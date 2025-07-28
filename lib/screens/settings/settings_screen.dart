import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_theme.dart';
import '../../utils/app_localizations_context.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          _buildSettingsSection(
            context,
            l10n.account,
            [
              _buildSettingsItem(
                context,
                icon: Icons.person,
                title: l10n.profileSettings,
                subtitle: l10n.manageProfile,
                onTap: () => context.push('/edit-profile'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.verified_user,
                title: l10n.verification,
                subtitle: l10n.verifyAccount,
                onTap: () => context.push('/verification'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.security,
                title: l10n.privacy,
                subtitle: l10n.privacyDescription,
                onTap: () => context.push('/privacy-settings'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.shield,
                title: l10n.safetyAndSecurity,
                subtitle: l10n.manageSafety,
                onTap: () => context.push('/safety'),
              ),
            ],
          ),
          
          _buildSettingsSection(
            context,
            l10n.appPreferences,
            [
              _buildSettingsItem(
                context,
                icon: Icons.language,
                title: l10n.language,
                subtitle: l10n.chooseLanguage,
                onTap: () => context.push('/language-settings'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.notifications,
                title: l10n.notifications,
                subtitle: l10n.manageNotifications,
                onTap: () {
                  // TODO: Navigate to notification settings
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.palette,
                title: l10n.theme,
                subtitle: l10n.themeDescription,
                onTap: () {
                  // TODO: Navigate to theme settings
                },
              ),
            ],
          ),
          
          _buildSettingsSection(
            context,
            l10n.runningPreferences,
            [
              _buildSettingsItem(
                context,
                icon: Icons.schedule,
                title: l10n.preferredTimes,
                subtitle: l10n.setPreferredTimes,
                onTap: () {
                  // TODO: Navigate to time preferences
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.speed,
                title: l10n.paceAndDistance,
                subtitle: l10n.configureRunning,
                onTap: () {
                  // TODO: Navigate to pace/distance settings
                },
              ),
            ],
          ),
          
          _buildSettingsSection(
            context,
            l10n.safety,
            [
              _buildSettingsItem(
                context,
                icon: Icons.emergency,
                title: l10n.emergencyContacts,
                subtitle: l10n.manageEmergencyContacts,
                onTap: () => context.push('/emergency-settings'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.gps_fixed,
                title: l10n.locationSharing,
                subtitle: l10n.controlLocationSharing,
                onTap: () => context.push('/privacy-settings'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.menu_book,
                title: l10n.safetyGuidelines,
                subtitle: l10n.learnSafetyTips,
                onTap: () => context.push('/safety-guidelines'),
              ),
            ],
          ),
          
          _buildSettingsSection(
            context,
            l10n.about,
            [
              _buildSettingsItem(
                context,
                icon: Icons.info,
                title: l10n.appVersion,
                subtitle: '1.0.0',
                showArrow: false,
                onTap: () {},
              ),
              _buildSettingsItem(
                context,
                icon: Icons.help,
                title: l10n.helpAndSupport,
                subtitle: l10n.getHelp,
                onTap: () {
                  // TODO: Navigate to help
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.policy,
                title: l10n.privacyPolicy,
                subtitle: l10n.readPrivacyPolicy,
                onTap: () {
                  // TODO: Navigate to privacy policy
                },
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.sectionPadding,
          child: Text(
            title,
            style: AppTypography.h6.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.card,
          ),
          child: Column(children: children),
        ),
        SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.card,
        child: Padding(
          padding: AppSpacing.listTilePadding,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) 
                trailing
              else if (showArrow)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}