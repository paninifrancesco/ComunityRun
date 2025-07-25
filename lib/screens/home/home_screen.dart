import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';
import '../../services/run_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/message_service.dart';
import '../../models/run.dart';
import '../../models/user_profile.dart';
import '../../widgets/run_card.dart';

// Provider for user location
final userLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  } catch (e) {
    return null;
  }
});

// Provider for nearby runs
final nearbyRunsProvider = StreamProvider.family<List<Run>, Position?>((ref, position) {
  if (position == null) {
    return Stream.value(<Run>[]);
  }
  
  final runService = ref.read(runServiceProvider);
  return runService.getNearbyRuns(
    latitude: position.latitude,
    longitude: position.longitude,
    radiusKm: 10.0, // Default 10km radius
    limit: 20,
  );
});

// Provider for filtering radius
final filterRadiusProvider = StateProvider<double>((ref) => 10.0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _loadingStates = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userLocation = ref.watch(userLocationProvider);
    final filterRadius = ref.watch(filterRadiusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Runs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Please sign in to view nearby runs'),
            );
          }
          return _buildRunsList(user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-run'),
        icon: const Icon(Icons.add),
        label: const Text('Create Run'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRunsList(UserProfile user) {
    final userLocation = ref.watch(userLocationProvider);
    final filterRadius = ref.watch(filterRadiusProvider);

    return userLocation.when(
      data: (position) {
        if (position == null) {
          return _buildLocationPermissionState();
        }

        final nearbyRuns = ref.watch(nearbyRunsProvider(position));
        return nearbyRuns.when(
          data: (runs) => _buildRunsListView(runs, user, position),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildLocationErrorState(),
    );
  }

  Widget _buildRunsListView(List<Run> runs, UserProfile user, Position position) {
    if (runs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(nearbyRunsProvider(position));
        ref.invalidate(userLocationProvider);
      },
      child: Column(
        children: [
          _buildLocationHeader(position),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: runs.length,
              itemBuilder: (context, index) {
                final run = runs[index];
                return _buildRunCardWithProfile(run, user.uid);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHeader(Position position) {
    final filterRadius = ref.watch(filterRadiusProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing runs within ${filterRadius.toStringAsFixed(0)}km',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showFilterDialog(context),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildRunCardWithProfile(Run run, String currentUserId) {
    final userProfileService = ref.read(userProfileServiceProvider);
    
    return FutureBuilder<UserProfile?>(
      future: userProfileService.getUserProfileOnce(run.creatorId),
      builder: (context, snapshot) {
        final creatorProfile = snapshot.data;
        final isUserParticipant = run.participants.contains(currentUserId);
        final isUserCreator = run.creatorId == currentUserId;
        final isLoading = _loadingStates[run.id] ?? false;

        return RunCard(
          run: run,
          creatorProfile: creatorProfile,
          isUserParticipant: isUserParticipant,
          isUserCreator: isUserCreator,
          isLoading: isLoading,
          onJoinPressed: () => _joinRun(run.id, currentUserId),
          onLeavePressed: () => _leaveRun(run.id, currentUserId),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 60), // Space for location header
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: 5,
            itemBuilder: (context, index) => const RunCardSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_run,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No runs found nearby',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to create a run in your area!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPermissionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Location Permission Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We need location access to show you nearby runs. Please enable location permissions in your device settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(userLocationProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_disabled,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Location Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to get your current location. Please check your location settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(userLocationProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(currentUserProvider);
                ref.invalidate(userLocationProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final currentRadius = ref.read(filterRadiusProvider);
    double selectedRadius = currentRadius;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Runs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Search radius:'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Slider(
                      value: selectedRadius,
                      min: 1.0,
                      max: 50.0,
                      divisions: 49,
                      label: '${selectedRadius.toStringAsFixed(0)}km',
                      onChanged: (value) {
                        setState(() {
                          selectedRadius = value;
                        });
                      },
                    ),
                    Text(
                      '${selectedRadius.toStringAsFixed(0)} kilometers',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(filterRadiusProvider.notifier).state = selectedRadius;
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRun(String runId, String userId) async {
    setState(() {
      _loadingStates[runId] = true;
    });

    try {
      final runService = ref.read(runServiceProvider);
      final messageService = ref.read(messageServiceProvider);
      final userProfile = await ref.read(userProfileServiceProvider).getUserProfileOnce(userId);
      
      await runService.joinRun(runId, userId);
      
      // Send system message
      if (userProfile != null) {
        await messageService.sendUserJoinedMessage(runId, userProfile.displayName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the run!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join run: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[runId] = false;
        });
      }
    }
  }

  Future<void> _leaveRun(String runId, String userId) async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Run'),
        content: const Text('Are you sure you want to leave this run?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (shouldLeave != true) return;

    setState(() {
      _loadingStates[runId] = true;
    });

    try {
      final runService = ref.read(runServiceProvider);
      final messageService = ref.read(messageServiceProvider);
      final userProfile = await ref.read(userProfileServiceProvider).getUserProfileOnce(userId);
      
      await runService.leaveRun(runId, userId);
      
      // Send system message
      if (userProfile != null) {
        await messageService.sendUserLeftMessage(runId, userProfile.displayName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left the run successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave run: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[runId] = false;
        });
      }
    }
  }
}