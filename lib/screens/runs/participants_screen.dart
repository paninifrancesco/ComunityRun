import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/run.dart';
import '../../models/user_profile.dart';
import '../../services/run_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_service.dart';

class ParticipantsScreen extends ConsumerStatefulWidget {
  final String runId;

  const ParticipantsScreen({
    super.key,
    required this.runId,
  });

  @override
  ConsumerState<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends ConsumerState<ParticipantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runService = ref.read(runServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(
              icon: Icon(Icons.group),
              text: 'Confirmed',
            ),
            Tab(
              icon: Icon(Icons.queue),
              text: 'Waiting List',
            ),
          ],
        ),
      ),
      body: StreamBuilder<Run?>(
        stream: runService.getRun(widget.runId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final run = snapshot.data;
          if (run == null) {
            return _buildNotFoundState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildParticipantsList(
                run.participants,
                run,
                'No confirmed participants yet',
                isConfirmedList: true,
              ),
              _buildParticipantsList(
                run.waitingList,
                run,
                'No one on the waiting list',
                isConfirmedList: false,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticipantsList(
    List<String> participantIds,
    Run run,
    String emptyMessage, {
    required bool isConfirmedList,
  }) {
    if (participantIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConfirmedList ? Icons.group_off : Icons.queue,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh will happen automatically through the StreamBuilder
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: participantIds.length,
        itemBuilder: (context, index) {
          final participantId = participantIds[index];
          return _buildParticipantTile(
            participantId,
            run,
            isConfirmedList: isConfirmedList,
            position: index + 1,
          );
        },
      ),
    );
  }

  Widget _buildParticipantTile(
    String participantId,
    Run run, {
    required bool isConfirmedList,
    required int position,
  }) {
    final userProfileService = ref.read(userProfileServiceProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isRunCreator = currentUser?.uid == run.creatorId;
    final isCurrentUser = currentUser?.uid == participantId;

    return FutureBuilder<UserProfile?>(
      future: userProfileService.getUserProfileOnce(participantId),
      builder: (context, snapshot) {
        final participant = snapshot.data;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  backgroundImage: participant?.photoUrl != null
                      ? NetworkImage(participant!.photoUrl!)
                      : null,
                  child: participant?.photoUrl == null
                      ? Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                ),
                if (run.creatorId == participantId)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    participant?.displayName ?? 'Loading...',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (!isConfirmedList)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$position',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (participant?.bio != null && participant!.bio!.isNotEmpty)
                  Text(
                    participant.bio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (run.creatorId == participantId)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Organizer',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    if (isCurrentUser && run.creatorId != participantId)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: _buildParticipantActions(
              participantId,
              run,
              isRunCreator: isRunCreator,
              isCurrentUser: isCurrentUser,
              isConfirmedList: isConfirmedList,
            ),
            onTap: () => _showParticipantDetails(participant, run, participantId),
          ),
        );
      },
    );
  }

  Widget? _buildParticipantActions(
    String participantId,
    Run run, {
    required bool isRunCreator,
    required bool isCurrentUser,
    required bool isConfirmedList,
  }) {
    // Run creator cannot remove themselves
    if (isCurrentUser && run.creatorId == participantId) {
      return null;
    }

    // Only run creator or the participant themselves can take actions
    if (!isRunCreator && !isCurrentUser) {
      return null;
    }

    return PopupMenuButton<String>(
      onSelected: (value) => _handleParticipantAction(
        value,
        participantId,
        run,
        isConfirmedList: isConfirmedList,
      ),
      itemBuilder: (context) {
        List<PopupMenuEntry<String>> items = [];

        if (isCurrentUser) {
          // User can remove themselves
          items.add(
            PopupMenuItem(
              value: 'leave',
              child: ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red.shade600),
                title: Text(
                  isConfirmedList ? 'Leave Run' : 'Leave Waitlist',
                  style: TextStyle(color: Colors.red.shade600),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
        }

        if (isRunCreator && !isCurrentUser) {
          // Run creator can manage other participants
          if (isConfirmedList) {
            items.add(
              const PopupMenuItem(
                value: 'move_to_waitlist',
                child: ListTile(
                  leading: Icon(Icons.queue, color: Colors.orange),
                  title: Text('Move to Waitlist'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            );
          } else {
            items.add(
              const PopupMenuItem(
                value: 'promote_to_confirmed',
                child: ListTile(
                  leading: Icon(Icons.arrow_upward, color: Colors.green),
                  title: Text('Promote to Confirmed'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            );
          }

          items.add(
            PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red.shade600),
                title: Text(
                  'Remove from Run',
                  style: TextStyle(color: Colors.red.shade600),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
        }

        return items;
      },
      child: const Icon(Icons.more_vert),
    );
  }

  void _handleParticipantAction(
    String action,
    String participantId,
    Run run, {
    required bool isConfirmedList,
  }) {
    switch (action) {
      case 'leave':
        _leaveRun(participantId, run.id);
        break;
      case 'move_to_waitlist':
        _moveToWaitlist(participantId, run.id);
        break;
      case 'promote_to_confirmed':
        _promoteToConfirmed(participantId, run.id);
        break;
      case 'remove':
        _removeParticipant(participantId, run.id);
        break;
    }
  }

  void _showParticipantDetails(
    UserProfile? participant,
    Run run,
    String participantId,
  ) {
    if (participant == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: participant.photoUrl != null
                  ? NetworkImage(participant.photoUrl!)
                  : null,
              child: participant.photoUrl == null
                  ? Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              participant.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (participant.bio != null && participant.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                participant.bio!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            if (run.creatorId == participantId)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Run Organizer',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _leaveRun(String participantId, String runId) async {
    final confirmed = await _showConfirmationDialog(
      'Leave Run',
      'Are you sure you want to leave this run?',
      confirmText: 'Leave',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final runService = ref.read(runServiceProvider);
      await runService.leaveRun(runId, participantId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully left the run')),
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _moveToWaitlist(String participantId, String runId) async {
    // This would require a new method in RunService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Move to waitlist functionality coming soon')),
    );
  }

  Future<void> _promoteToConfirmed(String participantId, String runId) async {
    // This would require a new method in RunService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Promote to confirmed functionality coming soon')),
    );
  }

  Future<void> _removeParticipant(String participantId, String runId) async {
    final confirmed = await _showConfirmationDialog(
      'Remove Participant',
      'Are you sure you want to remove this participant from the run?',
      confirmText: 'Remove',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final runService = ref.read(runServiceProvider);
      await runService.leaveRun(runId, participantId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participant removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove participant: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool?> _showConfirmationDialog(
    String title,
    String content, {
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Run not found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'The run you\'re looking for doesn\'t exist or has been deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}