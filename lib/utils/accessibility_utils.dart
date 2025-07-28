import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccessibilityUtils {
  static void announceToScreenReader(BuildContext context, String message) {
    // Note: SemanticsService requires import 'package:flutter/semantics.dart';
    // For now, we'll use a simple print for debugging
    debugPrint('Accessibility announcement: $message');
  }

  static void provideTactileFeedback() {
    HapticFeedback.lightImpact();
  }

  static void provideSelectionFeedback() {
    HapticFeedback.selectionClick();
  }

  static String getRunDifficultyA11yLabel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'Beginner level run, suitable for new runners';
      case 'intermediate':
        return 'Intermediate level run, requires some running experience';
      case 'advanced':
        return 'Advanced level run, requires significant running experience';
      default:
        return '$difficulty level run';
    }
  }

  static String getRunTypeA11yLabel(String runType) {
    switch (runType.toLowerCase()) {
      case 'easy':
        return 'Easy run, relaxed pace for recovery or social running';
      case 'tempo':
        return 'Tempo run, comfortably hard effort';
      case 'intervals':
        return 'Interval training, alternating high and low intensity';
      case 'long':
        return 'Long run, extended distance for endurance';
      case 'fartlek':
        return 'Fartlek run, unstructured speed play';
      default:
        return '$runType run';
    }
  }

  static String getDistanceA11yLabel(double? distance) {
    if (distance == null) return 'Distance not specified';
    return '${distance.toStringAsFixed(1)} kilometers';
  }

  static String getPaceA11yLabel(String? pace) {
    if (pace == null) return 'Pace not specified';
    return 'Target pace $pace per kilometer';
  }

  static String getDateTimeA11yLabel(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return 'In ${difference.inDays} days at ${_formatTime(dateTime)}';
    } else {
      return 'On ${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
    }
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  static String _formatDate(DateTime dateTime) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  static String getParticipantsA11yLabel(int current, int max) {
    final available = max - current;
    if (available == 0) {
      return 'Run is full with $current out of $max participants';
    } else if (available == 1) {
      return '$current out of $max participants, 1 spot available';
    } else {
      return '$current out of $max participants, $available spots available';
    }
  }

  static String getLocationA11yLabel(String location) {
    return 'Meeting point: $location';
  }

  static Widget makeAccessible({
    required Widget child,
    required String semanticLabel,
    String? hint,
    bool isButton = false,
    bool isHeader = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: isButton,
      header: isHeader,
      child: isButton && onTap != null
          ? GestureDetector(
              onTap: () {
                provideSelectionFeedback();
                onTap();
              },
              child: child,
            )
          : child,
    );
  }

  static Widget buildFocusableCard({
    required Widget child,
    required String semanticLabel,
    String? hint,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          provideTactileFeedback();
        }
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            decoration: hasFocus
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).focusColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Semantics(
              label: semanticLabel,
              hint: hint,
              button: onTap != null,
              selected: isSelected,
              child: InkWell(
                onTap: onTap != null
                    ? () {
                        provideSelectionFeedback();
                        onTap();
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  static const double minimumTapTarget = 48.0;

  static Widget ensureMinimumTapTarget({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: minimumTapTarget,
      height: minimumTapTarget,
      child: onTap != null
          ? InkWell(
              onTap: () {
                provideSelectionFeedback();
                onTap();
              },
              borderRadius: BorderRadius.circular(24),
              child: Center(child: child),
            )
          : Center(child: child),
    );
  }

  static EdgeInsets get accessiblePadding => const EdgeInsets.all(16.0);
  
  static EdgeInsets get listItemPadding => const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      );

  static bool isLargeTextScale(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1.0) > 1.3;
  }

  static double getScaledFontSize(BuildContext context, double baseSize) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(1.0);
    // Cap the scaling to prevent excessive font sizes
    final cappedScale = scaleFactor.clamp(0.8, 2.0);
    return baseSize * cappedScale;
  }

  static bool reduceMotions(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static Duration getAnimationDuration(BuildContext context) {
    return reduceMotions(context) 
        ? Duration.zero 
        : const Duration(milliseconds: 200);
  }
}

// Extension for easier access to accessibility features
extension AccessibilityExtension on Widget {
  Widget withSemantics({
    required String label,
    String? hint,
    bool isButton = false,
    bool isHeader = false,
    VoidCallback? onTap,
  }) {
    return AccessibilityUtils.makeAccessible(
      child: this,
      semanticLabel: label,
      hint: hint,
      isButton: isButton,
      isHeader: isHeader,
      onTap: onTap,
    );
  }

  Widget asFocusableCard({
    required String semanticLabel,
    String? hint,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return AccessibilityUtils.buildFocusableCard(
      child: this,
      semanticLabel: semanticLabel,
      hint: hint,
      onTap: onTap,
      isSelected: isSelected,
    );
  }

  Widget withMinimumTapTarget({VoidCallback? onTap}) {
    return AccessibilityUtils.ensureMinimumTapTarget(
      child: this,
      onTap: onTap,
    );
  }
}