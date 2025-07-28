import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// Utility class for locale-specific formatting
class LocaleUtils {
  static String formatDistance(BuildContext context, double distance) {
    final l10n = context.l10n;
    return '${distance.toStringAsFixed(1)} ${l10n.kmUnit}';
  }

  static String formatPace(BuildContext context, int minutes, int seconds) {
    final l10n = context.l10n;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} ${l10n.minPerKm}';
  }

  static String formatDateTime(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context);
    
    if (locale.languageCode == 'it') {
      // Italian date format: dd/MM/yyyy HH:mm
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
             '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // English date format: MM/dd/yyyy HH:mm
      return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}/${dateTime.year} '
             '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  static String formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final inputDate = DateTime(date.year, date.month, date.day);

    final l10n = context.l10n;

    if (inputDate == today) {
      return l10n.today;
    } else if (inputDate == tomorrow) {
      return l10n.tomorrow;
    } else if (locale.languageCode == 'it') {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  static String formatTime(BuildContext context, TimeOfDay time) {
    final locale = Localizations.localeOf(context);
    
    if (locale.languageCode == 'it') {
      // 24-hour format for Italian
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // 12-hour format for English
      final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
      final period = time.hour < 12 ? 'AM' : 'PM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  static String getTimeOfDayLabel(BuildContext context, TimeOfDay time) {
    final l10n = context.l10n;
    
    if (time.hour < 12) {
      return l10n.morning;
    } else if (time.hour < 18) {
      return l10n.afternoon;
    } else {
      return l10n.evening;
    }
  }

  static String getDifficultyTranslation(BuildContext context, String difficulty) {
    final l10n = context.l10n;
    
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'principiante':
        return l10n.beginner;
      case 'intermediate':
      case 'intermedio':
        return l10n.intermediate;
      case 'advanced':
      case 'avanzato':
        return l10n.advanced;
      default:
        return difficulty;
    }
  }

  static String getRunTypeTranslation(BuildContext context, String runType) {
    final l10n = context.l10n;
    
    switch (runType.toLowerCase()) {
      case 'easy':
      case 'facile':
        return l10n.easy;
      case 'tempo':
        return l10n.tempo;
      case 'intervals':
      case 'intervalli':
        return l10n.intervals;
      case 'long':
      case 'lunga':
        return l10n.longRun;
      case 'fartlek':
        return l10n.fartlek;
      default:
        return runType;
    }
  }

  static List<String> getSupportedLanguages() {
    return ['en', 'it'];
  }

  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'it':
        return 'Italiano';
      default:
        return languageCode;
    }
  }

  static bool isRTL(String languageCode) {
    // Add RTL languages here if needed
    return false;
  }
}