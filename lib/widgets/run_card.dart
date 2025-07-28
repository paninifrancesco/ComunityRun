import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/run.dart';
import '../models/user_profile.dart';
import '../constants/app_theme.dart';
import '../utils/accessibility_utils.dart';

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
    final semanticLabel = _buildSemanticLabel(context);
    final hint = 'Double tap to view run details';
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.card,
      ),
      child: AccessibilityUtils.buildFocusableCard(
        semanticLabel: semanticLabel,
        hint: hint,
        onTap: () {
          AccessibilityUtils.announceToScreenReader(
            context,
            'Opening ${run.title} run details',
          );
          context.push('/run/${run.id}');
        },
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: AppSpacing.md),
              _buildRunDetails(context),
              SizedBox(height: AppSpacing.md),
              _buildLocationAndTime(context),
              SizedBox(height: AppSpacing.lg),
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
        Semantics(
          label: 'Run creator: ${creatorProfile?.displayName ?? 'Unknown'}',
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: creatorProfile?.photoUrl != null
                ? NetworkImage(creatorProfile!.photoUrl!)
                : null,
            child: creatorProfile?.photoUrl == null
                ? Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                run.title,
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ).withSemantics(
                label: 'Run title: ${run.title}',
                isHeader: true,
              ),
              const SizedBox(height: 2),
              Text(
                'by ${creatorProfile?.displayName ?? 'Unknown'}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
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

    return Semantics(
      label: AccessibilityUtils.getRunDifficultyA11yLabel(run.difficulty),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: chipColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          run.difficulty.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: chipColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRunDetails(BuildContext context) {
    return Row(
      children: [
        if (run.estimatedDistance != null) ...[
          Icon(Icons.straighten, size: 16, color: AppColors.textSecondary),
          SizedBox(width: AppSpacing.xs),
          Semantics(
            label: AccessibilityUtils.getDistanceA11yLabel(run.estimatedDistance),
            child: Text(
              '${run.estimatedDistance!.toStringAsFixed(1)}km',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
        ],
        if (run.estimatedPace != null) ...[
          Icon(Icons.speed, size: 16, color: AppColors.textSecondary),
          SizedBox(width: AppSpacing.xs),
          Semantics(
            label: AccessibilityUtils.getPaceA11yLabel(run.estimatedPace),
            child: Text(
              '${run.estimatedPace}/km',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
        ],
        if (run.estimatedDurationMinutes != null) ...[
          Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
          SizedBox(width: AppSpacing.xs),
          Semantics(
            label: 'Estimated duration ${run.estimatedDurationMinutes} minutes',
            child: Text(
              '${run.estimatedDurationMinutes}min',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
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
              color: Colors.orange.withValues(alpha: 0.1),
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
          color: Colors.grey.withValues(alpha: 0.1),
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

  String _buildSemanticLabel(BuildContext context) {
    final creatorName = creatorProfile?.displayName ?? 'Unknown';
    final distance = run.estimatedDistance != null 
        ? '${run.estimatedDistance!.toStringAsFixed(1)} kilometers' 
        : 'Distance not specified';
    final pace = run.estimatedPace != null 
        ? 'Pace ${run.estimatedPace} per kilometer' 
        : 'Pace not specified';
    final dateTime = AccessibilityUtils.getDateTimeA11yLabel(run.dateTime);
    final location = AccessibilityUtils.getLocationA11yLabel(run.startLocationName);
    final participants = AccessibilityUtils.getParticipantsA11yLabel(
      run.participants.length, 
      run.maxParticipants,
    );
    final difficulty = AccessibilityUtils.getRunDifficultyA11yLabel(run.difficulty);

    return '${run.title}. Run created by $creatorName. $difficulty. $distance. $pace. $dateTime. $location. $participants.';
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