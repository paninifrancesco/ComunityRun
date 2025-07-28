import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/run.dart';
import '../../models/user_profile.dart';
import '../../services/run_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/message_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/safety_service.dart';
import 'edit_run_screen.dart';
import 'participants_screen.dart';
import '../profile/report_user_screen.dart';

class RunDetailsScreen extends ConsumerStatefulWidget {
  final String runId;
  
  const RunDetailsScreen({
    super.key,
    required this.runId,
  });

  @override
  ConsumerState<RunDetailsScreen> createState() => _RunDetailsScreenState();
}

class _RunDetailsScreenState extends ConsumerState<RunDetailsScreen> {
  bool _isJoinLeaveLoading = false;

  @override
  Widget build(BuildContext context) {
    final runService = ref.read(runServiceProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return _buildUnauthenticatedState();
          }
          
          return StreamBuilder<Run?>(
            stream: runService.getRun(widget.runId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }
              
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }
              
              final run = snapshot.data;
              if (run == null) {
                return _buildNotFoundState();
              }
              
              return _buildRunDetailsView(run, user);
            },
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildRunDetailsView(Run run, UserProfile currentUser) {
    final isUserCreator = run.creatorId == currentUser.uid;
    final isUserParticipant = run.participants.contains(currentUser.uid);
    final isUserOnWaitlist = run.waitingList.contains(currentUser.uid);

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(run, isUserCreator),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRunHeader(run),
                const SizedBox(height: 24),
                _buildRunDetailsCard(run),
                const SizedBox(height: 24),
                _buildLocationSection(run),
                const SizedBox(height: 24),
                _buildCreatorSection(run),
                const SizedBox(height: 24),
                _buildParticipantsSection(run, currentUser.uid),
                if (run.description != null && run.description!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildDescriptionSection(run),
                ],
                if (run.meetingInstructions != null && run.meetingInstructions!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildMeetingInstructionsSection(run),
                ],
                const SizedBox(height: 24),
                _buildSafetySection(run),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Run run, bool isUserCreator) {
    final currentUser = ref.watch(currentUserProvider).value;
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          run.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.directions_run,
              size: 80,
              color: Colors.white54,
            ),
          ),
        ),
      ),
      actions: [
        if (isUserCreator) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditRun(run.id),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Run'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ] else if (currentUser != null && run.creatorId != currentUser.uid) ...[
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'report') {
                await _reportUser(run.creatorId, run.creatorName ?? 'Unknown User', run.id);
              } else if (value == 'block') {
                await _blockUser(run.creatorId, run.creatorName ?? 'Unknown User');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: ListTile(
                  leading: Icon(Icons.report, color: Colors.orange),
                  title: Text('Report User'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: ListTile(
                  leading: Icon(Icons.block, color: Colors.red),
                  title: Text('Block User'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRunHeader(Run run) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatusChip(run.status),
            const Spacer(),
            _buildDifficultyChip(run.difficulty),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.schedule, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              _formatDateTime(run.dateTime),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'scheduled':
        chipColor = Colors.blue;
        statusText = 'Scheduled';
        break;
      case 'active':
        chipColor = Colors.green;
        statusText = 'Active';
        break;
      case 'completed':
        chipColor = Colors.grey;
        statusText = 'Completed';
        break;
      case 'cancelled':
        chipColor = Colors.red;
        statusText = 'Cancelled';
        break;
      default:
        chipColor = Colors.grey;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color chipColor;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        chipColor = Colors.green;
        break;
      case 'moderate':
        chipColor = Colors.orange;
        break;
      case 'hard':
        chipColor = Colors.red;
        break;
      case 'expert':
        chipColor = Colors.purple;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRunDetailsCard(Run run) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Run Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (run.estimatedDistance != null)
              _buildDetailRow(
                Icons.straighten,
                'Distance',
                '${run.estimatedDistance!.toStringAsFixed(1)} km',
              ),
            if (run.estimatedPace != null)
              _buildDetailRow(
                Icons.speed,
                'Pace',
                '${run.estimatedPace}/km',
              ),
            if (run.estimatedDurationMinutes != null)
              _buildDetailRow(
                Icons.access_time,
                'Duration',
                '${run.estimatedDurationMinutes} minutes',
              ),
            _buildDetailRow(
              Icons.group,
              'Participants',
              '${run.participants.length}/${run.maxParticipants}',
            ),
            if (run.tags.isNotEmpty)
              _buildDetailRow(
                Icons.local_offer,
                'Tags',
                run.tags.join(', '),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildLocationSection(Run run) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    run.startLocationName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Map coming soon',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorSection(Run run) {
    final userProfileService = ref.read(userProfileServiceProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organized by',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<UserProfile?>(
              future: userProfileService.getUserProfileOnce(run.creatorId),
              builder: (context, snapshot) {
                final creator = snapshot.data;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    backgroundImage: creator?.photoUrl != null
                        ? NetworkImage(creator!.photoUrl!)
                        : null,
                    child: creator?.photoUrl == null
                        ? Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
                  ),
                  title: Text(
                    creator?.displayName ?? 'Loading...',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: creator?.bio != null && creator!.bio!.isNotEmpty
                      ? Text(creator.bio!)
                      : null,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection(Run run, String currentUserId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (run.participants.isNotEmpty)
                  TextButton(
                    onPressed: () => _navigateToParticipants(run.id),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (run.participants.isEmpty)
              const Text(
                'No participants yet. Be the first to join!',
                style: TextStyle(color: Colors.grey),
              )
            else ...[
              _buildParticipantsList(run.participants, 'Confirmed', 5),
              if (run.waitingList.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildParticipantsList(run.waitingList, 'Waiting List', 3),
              ],
            ],
            const SizedBox(height: 16),
            _buildJoinLeaveButton(run, currentUserId),
            if (run.participants.contains(currentUserId)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/chat/${run.id}'),
                  icon: const Icon(Icons.chat),
                  label: const Text('Open Chat'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList(List<String> participantIds, String title, int maxDisplay) {
    final displayCount = participantIds.length > maxDisplay ? maxDisplay : participantIds.length;
    final remaining = participantIds.length - displayCount;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${participantIds.length})',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...participantIds
            .take(displayCount)
            .map((participantId) => _buildParticipantTile(participantId))
            .toList(),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'and $remaining more...',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildParticipantTile(String participantId) {
    final userProfileService = ref.read(userProfileServiceProvider);
    
    return FutureBuilder<UserProfile?>(
      future: userProfileService.getUserProfileOnce(participantId),
      builder: (context, snapshot) {
        final participant = snapshot.data;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                backgroundImage: participant?.photoUrl != null
                    ? NetworkImage(participant!.photoUrl!)
                    : null,
                child: participant?.photoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  participant?.displayName ?? 'Loading...',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJoinLeaveButton(Run run, String currentUserId) {
    final isUserCreator = run.creatorId == currentUserId;
    final isUserParticipant = run.participants.contains(currentUserId);
    final isUserOnWaitlist = run.waitingList.contains(currentUserId);

    if (isUserCreator) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            // TODO: Navigate to manage run screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Manage functionality coming soon')),
            );
          },
          child: const Text('Manage Run'),
        ),
      );
    }

    if (isUserParticipant) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isJoinLeaveLoading ? null : () => _leaveRun(run.id, currentUserId),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: _isJoinLeaveLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Leave Run'),
        ),
      );
    }

    if (isUserOnWaitlist) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isJoinLeaveLoading ? null : () => _leaveRun(run.id, currentUserId),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
          ),
          child: _isJoinLeaveLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Leave Waitlist'),
        ),
      );
    }

    if (run.isFull && !run.allowWaitingList) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          child: const Text('Run is Full'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isJoinLeaveLoading ? null : () => _joinRun(run.id, currentUserId),
        child: _isJoinLeaveLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(run.isFull ? 'Join Waitlist' : 'Join Run'),
      ),
    );
  }

  Widget _buildDescriptionSection(Run run) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              run.description!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingInstructionsSection(Run run) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meeting Instructions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                run.meetingInstructions!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetySection(Run run) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Safety Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '• Always run in well-lit, populated areas\n'
              '• Inform someone of your running plans\n'
              '• Stay hydrated and listen to your body\n'
              '• Follow local traffic rules and signals',
              style: TextStyle(height: 1.5),
            ),
            if (run.weather != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Check weather conditions before running',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
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
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Run Not Found')),
      body: const Center(
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
      ),
    );
  }

  Widget _buildUnauthenticatedState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In Required')),
      body: const Center(
        child: Text('Please sign in to view run details'),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }

  void _showAllParticipants(Run run) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'All Participants',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (run.participants.isNotEmpty) ...[
                      Text(
                        'Confirmed (${run.participants.length})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      ...run.participants.map((id) => _buildParticipantTile(id)),
                    ],
                    if (run.waitingList.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Waiting List (${run.waitingList.length})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      ...run.waitingList.map((id) => _buildParticipantTile(id)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Run'),
        content: const Text(
          'Are you sure you want to delete this run? This action cannot be undone and all participants will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteRun();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRun(String runId, String userId) async {
    setState(() {
      _isJoinLeaveLoading = true;
    });

    try {
      final runService = ref.read(runServiceProvider);
      final messageService = ref.read(messageServiceProvider);
      final notificationService = ref.read(notificationServiceProvider);
      final userProfile = await ref.read(userProfileServiceProvider).getUserProfileOnce(userId);
      final run = await runService.getRunOnce(runId);
      
      await runService.joinRun(runId, userId);
      
      if (userProfile != null && run != null) {
        // Send system message to chat
        await messageService.sendUserJoinedMessage(runId, userProfile.displayName);
        
        // Send notification to run creator
        await notificationService.sendNewParticipantNotification(
          runId: runId,
          runTitle: run.title,
          participantName: userProfile.displayName,
          creatorUserId: run.creatorId,
        );
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
          _isJoinLeaveLoading = false;
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
      _isJoinLeaveLoading = true;
    });

    try {
      final runService = ref.read(runServiceProvider);
      final messageService = ref.read(messageServiceProvider);
      final notificationService = ref.read(notificationServiceProvider);
      final userProfile = await ref.read(userProfileServiceProvider).getUserProfileOnce(userId);
      final run = await runService.getRunOnce(runId);
      
      await runService.leaveRun(runId, userId);
      
      if (userProfile != null && run != null) {
        // Send system message to chat
        await messageService.sendUserLeftMessage(runId, userProfile.displayName);
        
        // Send notification to run creator
        await notificationService.sendParticipantLeftNotification(
          runId: runId,
          runTitle: run.title,
          participantName: userProfile.displayName,
          creatorUserId: run.creatorId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left the run successfully')),
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
          _isJoinLeaveLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditRun(String runId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditRunScreen(runId: runId),
      ),
    );

    // If edit was successful, show success message
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Run updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _navigateToParticipants(String runId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParticipantsScreen(runId: runId),
      ),
    );
  }

  Future<void> _deleteRun() async {
    try {
      final runService = ref.read(runServiceProvider);
      await runService.deleteRun(widget.runId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Run deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete run: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reportUser(String reportedUserId, String reportedUserName, String runId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReportUserScreen(
          reportedUserId: reportedUserId,
          reportedUserName: reportedUserName,
          runId: runId,
        ),
      ),
    );

    if (result == true && mounted) {
      // Report was submitted successfully
      // The success message is shown in the ReportUserScreen
    }
  }

  Future<void> _blockUser(String blockedUserId, String blockedUserName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block $blockedUserName? You will no longer see their runs and they cannot join your runs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final currentUser = ref.watch(currentUserProvider).value;
        if (currentUser == null) return;

        final safetyService = ref.read(safetyServiceProvider);
        final success = await safetyService.blockUser(
          blockerId: currentUser.uid,
          blockedUserId: blockedUserId,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$blockedUserName has been blocked'),
              backgroundColor: Colors.orange,
            ),
          );
          // Navigate back since the user is now blocked
          Navigator.of(context).pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to block user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}