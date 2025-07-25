import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/run.dart';
import '../models/user_profile.dart';

class RunCard extends StatelessWidget {
  final Run run;
  final UserProfile? creatorProfile;
  final VoidCallback? onJoinPressed;
  final VoidCallback? onLeavePressed;
  final bool isUserParticipant;
  final bool isUserCreator;
  final bool isLoading;

  const RunCard({
    super.key,
    required this.run,
    this.creatorProfile,
    this.onJoinPressed,
    this.onLeavePressed,
    this.isUserParticipant = false,
    this.isUserCreator = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/run/${run.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildRunDetails(context),
              const SizedBox(height: 12),
              _buildLocationAndTime(context),
              const SizedBox(height: 16),
              _buildParticipantsAndAction(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: creatorProfile?.photoUrl != null
              ? NetworkImage(creatorProfile!.photoUrl!)
              : null,
          child: creatorProfile?.photoUrl == null
              ? Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                run.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'by ${creatorProfile?.displayName ?? 'Unknown'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildDifficultyChip(context),
      ],
    );
  }

  Widget _buildDifficultyChip(BuildContext context) {
    Color chipColor;
    switch (run.difficulty.toLowerCase()) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        run.difficulty.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRunDetails(BuildContext context) {
    return Row(
      children: [
        if (run.estimatedDistance != null) ...[
          Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '${run.estimatedDistance!.toStringAsFixed(1)}km',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
        ],
        if (run.estimatedPace != null) ...[
          Icon(Icons.speed, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '${run.estimatedPace}/km',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
        ],
        if (run.estimatedDurationMinutes != null) ...[
          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '${run.estimatedDurationMinutes}min',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildLocationAndTime(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                run.startLocationName,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _formatDateTime(run.dateTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantsAndAction(BuildContext context) {
    return Row(
      children: [
        _buildParticipantInfo(context),
        const Spacer(),
        _buildActionButton(context),
      ],
    );
  }

  Widget _buildParticipantInfo(BuildContext context) {
    final participantCount = run.participants.length;
    final waitingCount = run.waitingList.length;
    
    return Row(
      children: [
        Icon(Icons.group, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$participantCount/${run.maxParticipants}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (waitingCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$waitingCount waiting',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (isUserCreator) {
      return OutlinedButton(
        onPressed: () => context.push('/run/${run.id}'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 32),
        ),
        child: const Text('Manage'),
      );
    }

    if (isUserParticipant) {
      return OutlinedButton(
        onPressed: isLoading ? null : onLeavePressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 32),
          foregroundColor: Colors.red,
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Leave'),
      );
    }

    if (run.isFull && !run.allowWaitingList) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Full',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onJoinPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 32),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(run.isFull ? 'Join Waitlist' : 'Join'),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final runDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(dateTime);

    if (runDate == today) {
      return 'Today at $timeString';
    } else if (runDate == tomorrow) {
      return 'Tomorrow at $timeString';
    } else if (dateTime.difference(now).inDays < 7) {
      final dayFormat = DateFormat('EEEE');
      return '${dayFormat.format(dateTime)} at $timeString';
    } else {
      final dateFormat = DateFormat('MMM d');
      return '${dateFormat.format(dateTime)} at $timeString';
    }
  }
}

class RunCardSkeleton extends StatelessWidget {
  const RunCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 150,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}