import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';
import '../../utils/app_localizations_context.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'system';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('language') ?? 'system';
      setState(() {
        _selectedLanguage = savedLanguage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
      setState(() {
        _selectedLanguage = languageCode;
      });
      
      // Show restart message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageCode == 'it' 
                  ? 'Riavvia l\'app per applicare le modifiche'
                  : 'Restart the app to apply changes'
            ),
            action: SnackBarAction(
              label: languageCode == 'it' ? 'OK' : 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving language: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language / Lingua'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Card(
            color: AppColors.info.withOpacity(0.1),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Language Settings',
                        style: AppTypography.h6.copyWith(color: AppColors.info),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Choose your preferred language for the app interface.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Scegli la tua lingua preferita per l\'interfaccia dell\'app.',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildLanguageOption(
            'system',
            'System Default / Predefinito del Sistema',
            'Use device language / Usa lingua del dispositivo',
            Icons.phone_android,
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          _buildLanguageOption(
            'en',
            'English',
            'English language',
            Icons.flag,
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          _buildLanguageOption(
            'it',
            'Italiano',
            'Lingua italiana',
            Icons.flag,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          Card(
            color: AppColors.warning.withOpacity(0.1),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Note / Nota',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'App restart required to fully apply language changes.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'È necessario riavviare l\'app per applicare completamente le modifiche alla lingua.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    String languageCode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedLanguage == languageCode;
    
    return Card(
      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => _saveLanguage(languageCode),
        borderRadius: AppBorderRadius.card,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primary 
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: isSelected 
                      ? AppColors.textOnPrimary 
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}