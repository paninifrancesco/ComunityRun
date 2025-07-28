import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

// Enhanced Button Components
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final Color? customColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final padding = _getPadding();
    final textStyle = _getTextStyle();

    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == AppButtonType.primary ? Colors.white : AppColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(text, style: textStyle),
            ],
          );

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: Padding(padding: padding, child: child),
        );
      case AppButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: Padding(padding: padding, child: child),
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: Padding(padding: padding, child: child),
        );
    }
  }

  ButtonStyle _getButtonStyle() {
    final baseColor = customColor ?? AppColors.primary;
    
    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: baseColor,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.button,
          ),
        );
      case AppButtonType.secondary:
        return OutlinedButton.styleFrom(
          foregroundColor: baseColor,
          side: BorderSide(color: baseColor),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.button,
          ),
        );
      case AppButtonType.text:
        return TextButton.styleFrom(
          foregroundColor: baseColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.button,
          ),
        );
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
        );
      case AppButtonSize.medium:
        return AppTypography.button;
      case AppButtonSize.large:
        return AppTypography.labelLarge;
    }
  }
}

enum AppButtonType { primary, secondary, text }
enum AppButtonSize { small, medium, large }

// Enhanced Card Component
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool elevated;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevated = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppBorderRadius.card,
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ]
            : null,
        border: !elevated
            ? Border.all(color: AppColors.border, width: 1)
            : null,
      ),
      margin: margin ?? 
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
      child: Padding(
        padding: padding ?? AppSpacing.cardPadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.card,
          child: card,
        ),
      );
    }

    return card;
  }
}

// Status Chip Component
class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipType type;
  final bool isSelected;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.background : colors.background.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: colors.border,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type != StatusChipType.neutral)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.indicator,
                  shape: BoxShape.circle,
                ),
              ),
            if (type != StatusChipType.neutral)
              const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? colors.textOnBackground : colors.text,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ChipColors _getColors() {
    switch (type) {
      case StatusChipType.success:
        return _ChipColors(
          background: AppColors.success,
          border: AppColors.success,
          text: AppColors.success,
          textOnBackground: Colors.white,
          indicator: AppColors.success,
        );
      case StatusChipType.warning:
        return _ChipColors(
          background: AppColors.warning,
          border: AppColors.warning,
          text: AppColors.warning,
          textOnBackground: Colors.white,
          indicator: AppColors.warning,
        );
      case StatusChipType.error:
        return _ChipColors(
          background: AppColors.error,
          border: AppColors.error,
          text: AppColors.error,
          textOnBackground: Colors.white,
          indicator: AppColors.error,
        );
      case StatusChipType.info:
        return _ChipColors(
          background: AppColors.info,
          border: AppColors.info,
          text: AppColors.info,
          textOnBackground: Colors.white,
          indicator: AppColors.info,
        );
      case StatusChipType.primary:
        return _ChipColors(
          background: AppColors.primary,
          border: AppColors.primary,
          text: AppColors.primary,
          textOnBackground: Colors.white,
          indicator: AppColors.primary,
        );
      case StatusChipType.neutral:
        return _ChipColors(
          background: AppColors.surfaceVariant,
          border: AppColors.border,
          text: AppColors.textSecondary,
          textOnBackground: AppColors.textPrimary,
          indicator: AppColors.textTertiary,
        );
    }
  }
}

class _ChipColors {
  final Color background;
  final Color border;
  final Color text;
  final Color textOnBackground;
  final Color indicator;

  _ChipColors({
    required this.background,
    required this.border,
    required this.text,
    required this.textOnBackground,
    required this.indicator,
  });
}

enum StatusChipType { success, warning, error, info, primary, neutral }

// Enhanced Input Field
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool required;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: RichText(
              text: TextSpan(
                text: label!,
                style: AppTypography.labelLarge,
                children: required
                    ? [
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            helperStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            errorStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

// Avatar Component
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final VoidCallback? onTap;
  final bool showBadge;
  final Color? badgeColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.onTap,
    this.showBadge = false,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );

    if (showBadge) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildInitials() {
    final initials = name?.isNotEmpty == true
        ? name!.split(' ').take(2).map((e) => e[0]).join().toUpperCase()
        : '?';
    
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// Section Header Component
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsets? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? 
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h3),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// Difficulty Badge Component
class DifficultyBadge extends StatelessWidget {
  final String difficulty;
  final bool showIcon;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getDifficultyColors(difficulty);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getDifficultyIcon(difficulty),
              size: 14,
              color: colors.foreground,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            difficulty.toUpperCase(),
            style: AppTypography.bodySmall.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  _DifficultyColors _getDifficultyColors(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'easy':
        return _DifficultyColors(
          background: AppColors.difficultyBeginner.withOpacity(0.1),
          foreground: AppColors.difficultyBeginner,
        );
      case 'intermediate':
      case 'medium':
        return _DifficultyColors(
          background: AppColors.difficultyIntermediate.withOpacity(0.1),
          foreground: AppColors.difficultyIntermediate,
        );
      case 'advanced':
      case 'hard':
        return _DifficultyColors(
          background: AppColors.difficultyAdvanced.withOpacity(0.1),
          foreground: AppColors.difficultyAdvanced,
        );
      default:
        return _DifficultyColors(
          background: AppColors.surfaceVariant,
          foreground: AppColors.textSecondary,
        );
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'easy':
        return Icons.speed;
      case 'intermediate':
      case 'medium':
        return Icons.trending_up;
      case 'advanced':
      case 'hard':
        return Icons.flash_on;
      default:
        return Icons.help_outline;
    }
  }
}

class _DifficultyColors {
  final Color background;
  final Color foreground;

  _DifficultyColors({
    required this.background,
    required this.foreground,
  });
}