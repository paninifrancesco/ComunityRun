import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_theme.dart';

class LoadingStates {
  // Simple loading indicator
  static Widget loading({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Center loading indicator
  static Widget center({String? message}) {
    return loading(message: message);
  }

  // List with header skeleton
  static Widget listWithHeader() {
    return Column(
      children: [
        // Header skeleton
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: 24,
              color: Colors.white,
            ),
          ),
        ),
        // List items skeleton
        Expanded(
          child: ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) => runCardSkeleton(),
          ),
        ),
      ],
    );
  }

  // Skeleton card for run cards
  static Widget runCardSkeleton() {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 120,
                          height: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Date and location
              Container(
                width: 200,
                height: 14,
                color: Colors.white,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 160,
                height: 14,
                color: Colors.white,
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Distance and pace
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Join button
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppBorderRadius.button,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // List skeleton
  static Widget listSkeleton({int itemCount = 5}) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => runCardSkeleton(),
    );
  }

  // Profile header skeleton
  static Widget profileHeaderSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Name
          Container(
            width: 150,
            height: 20,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Bio
          Container(
            width: 200,
            height: 14,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Button loading state
  static Widget buttonLoading({
    required String text,
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        disabledBackgroundColor: (color ?? AppColors.primary).withOpacity(0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                color?.withOpacity(0.8) ?? Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(text),
        ],
      ),
    );
  }

  // Search loading
  static Widget searchLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Searching for runs...',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  // Pagination loading
  static Widget paginationLoading() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

class ErrorStates {
  // Generic error widget
  static Widget error({
    required String message,
    String? title,
    VoidCallback? onRetry,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            if (title != null) ...[
              Text(
                title,
                style: AppTypography.h3.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Network error
  static Widget networkError({VoidCallback? onRetry}) {
    return error(
      title: 'Connection Problem',
      message: 'Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  // No data found
  static Widget noData({
    required String message,
    String? title,
    VoidCallback? onRefresh,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            if (title != null) ...[
              Text(
                title,
                style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Permission denied
  static Widget permissionDenied({
    required String message,
    VoidCallback? onSettings,
  }) {
    return error(
      title: 'Permission Required',
      message: message,
      icon: Icons.location_disabled,
      onRetry: onSettings,
    );
  }

  // Location error
  static Widget locationError({VoidCallback? onRetry}) {
    return error(
      title: 'Location Error',
      message: 'Unable to get your current location. Please enable location services and try again.',
      icon: Icons.location_off,
      onRetry: onRetry,
    );
  }
}

// Empty states for specific screens
class EmptyStates {
  static Widget noRuns() {
    return ErrorStates.noData(
      title: 'No Runs Found',
      message: 'There are no runs in your area yet. Be the first to create one!',
      icon: Icons.directions_run,
    );
  }

  static Widget noMessages() {
    return ErrorStates.noData(
      title: 'No Messages',
      message: 'Join a run to start chatting with other runners!',
      icon: Icons.chat_bubble_outline,
    );
  }

  static Widget noParticipants() {
    return ErrorStates.noData(
      title: 'No Participants Yet',
      message: 'Share your run to get more runners to join!',
      icon: Icons.group_outlined,
    );
  }
}