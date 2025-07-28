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
import '../../widgets/loading_widgets.dart';
import '../../constants/app_theme.dart';
import '../../utils/app_localizations_context.dart';
import '../runs/filter_screen.dart';

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

// Provider for nearby runs with filters
final nearbyRunsProvider = StreamProvider.family<List<Run>, Position?>((ref, position) {
  if (position == null) {
    return Stream.value(<Run>[]);
  }
  
  final runService = ref.read(runServiceProvider);
  final filters = ref.watch(runFiltersProvider);
  
  return runService.getNearbyRuns(
    latitude: position.latitude,
    longitude: position.longitude,
    radiusKm: filters.radiusKm,
    limit: 50, // Increased limit for filtering
  );
});

// Provider for filtering radius (kept for backward compatibility)
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearbyRuns),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _navigateToFilterScreen(),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final filters = ref.watch(runFiltersProvider);
                  final activeCount = filters.activeFilterCount;
                  if (activeCount > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          activeCount.toString(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textOnError,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
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
            return Center(
              child: Text(
                l10n.pleaseSignIn,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return _buildRunsList(user);
        },
        loading: () => LoadingStates.center(),
        error: (error, stack) => _buildErrorState(error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-run'),
        icon: const Icon(Icons.add),
        label: Text(l10n.createRun),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
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
          data: (runs) {
            final filteredRuns = _applyFiltersAndSorting(runs);
            return _buildRunsListView(filteredRuns, user, position);
          },
          loading: () => LoadingStates.listWithHeader(),
          error: (error, stack) => _buildErrorState(error),
        );
      },
      loading: () => LoadingStates.center(),
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
    final filters = ref.watch(runFiltersProvider);
    final l10n = context.l10n;
    
    return Container(
      padding: AppSpacing.screenPadding,
      color: AppColors.primary.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Showing runs within ${filters.radiusKm.toStringAsFixed(0)}km',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToFilterScreen(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                child: Text(
                  filters.activeFilterCount > 0 
                      ? '${l10n.filters} (${filters.activeFilterCount})'
                      : l10n.filter,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (filters.activeFilterCount > 0) ...[
            SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: _buildActiveFilterChips(filters),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActiveFilterChips(RunFilters filters) {
    List<Widget> chips = [];

    if (filters.startDate != null || filters.endDate != null) {
      chips.add(_buildFilterChip('Date Range', Icons.date_range));
    }
    if (filters.earliestTime != null || filters.latestTime != null) {
      chips.add(_buildFilterChip('Time', Icons.access_time));
    }
    if (filters.minDistance > 0.0 || filters.maxDistance < 50.0) {
      chips.add(_buildFilterChip('Distance', Icons.straighten));
    }
    if (filters.minPace != null || filters.maxPace != null) {
      chips.add(_buildFilterChip('Pace', Icons.speed));
    }
    if (filters.runTypes.isNotEmpty) {
      chips.add(_buildFilterChip('Run Types (${filters.runTypes.length})', Icons.directions_run));
    }
    if (filters.difficulties.isNotEmpty) {
      chips.add(_buildFilterChip('Difficulty (${filters.difficulties.length})', Icons.trending_up));
    }
    if (filters.availableSpotsOnly) {
      chips.add(_buildFilterChip('Available Spots', Icons.group));
    }
    if (filters.language != null) {
      chips.add(_buildFilterChip('Language', Icons.language));
    }
    if (filters.sortBy != RunSortOption.distance) {
      chips.add(_buildFilterChip('Sort: ${filters.sortBy.displayName}', Icons.sort));
    }

    return chips;
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
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

  List<Run> _applyFiltersAndSorting(List<Run> runs) {
    final filters = ref.read(runFiltersProvider);
    List<Run> filteredRuns = runs.where((run) {
      // Date range filter
      if (filters.startDate != null) {
        if (run.dateTime.isBefore(filters.startDate!)) {
          return false;
        }
      }
      if (filters.endDate != null) {
        if (run.dateTime.isAfter(filters.endDate!)) {
          return false;
        }
      }

      // Time of day filter
      if (filters.earliestTime != null) {
        final runTime = TimeOfDay.fromDateTime(run.dateTime);
        final earliestMinutes = filters.earliestTime!.hour * 60 + filters.earliestTime!.minute;
        final runMinutes = runTime.hour * 60 + runTime.minute;
        if (runMinutes < earliestMinutes) {
          return false;
        }
      }
      if (filters.latestTime != null) {
        final runTime = TimeOfDay.fromDateTime(run.dateTime);
        final latestMinutes = filters.latestTime!.hour * 60 + filters.latestTime!.minute;
        final runMinutes = runTime.hour * 60 + runTime.minute;
        if (runMinutes > latestMinutes) {
          return false;
        }
      }

      // Distance filter
      if (run.estimatedDistance != null) {
        if (run.estimatedDistance! < filters.minDistance || 
            run.estimatedDistance! > filters.maxDistance) {
          return false;
        }
      }

      // Pace filter (simplified - comparing strings)
      if (filters.minPace != null && run.estimatedPace != null) {
        if (run.estimatedPace!.compareTo(filters.minPace!) < 0) {
          return false;
        }
      }
      if (filters.maxPace != null && run.estimatedPace != null) {
        if (run.estimatedPace!.compareTo(filters.maxPace!) > 0) {
          return false;
        }
      }

      // Run type filter
      if (filters.runTypes.isNotEmpty) {
        if (!filters.runTypes.contains(run.runType)) {
          return false;
        }
      }

      // Difficulty filter
      if (filters.difficulties.isNotEmpty) {
        if (!filters.difficulties.contains(run.difficulty)) {
          return false;
        }
      }

      // Available spots filter
      if (filters.availableSpotsOnly) {
        if (run.isFull) {
          return false;
        }
      }

      // Language filter
      if (filters.language != null) {
        if (run.language != filters.language) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    switch (filters.sortBy) {
      case RunSortOption.distance:
        // Default sorting by distance (already sorted by FireStore geo query)
        break;
      case RunSortOption.startTime:
        filteredRuns.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case RunSortOption.recentlyCreated:
        filteredRuns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case RunSortOption.mostParticipants:
        filteredRuns.sort((a, b) => b.participants.length.compareTo(a.participants.length));
        break;
    }

    return filteredRuns;
  }

  void _navigateToFilterScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FilterScreen(),
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