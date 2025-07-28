import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'CommunityRun'**
  String get appTitle;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Discover tab label
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// Messages tab label
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Account settings section
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Profile settings menu item
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// Profile settings description
  ///
  /// In en, this message translates to:
  /// **'Manage your profile information'**
  String get manageProfile;

  /// Verification screen title
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// Verification description
  ///
  /// In en, this message translates to:
  /// **'Verify your account'**
  String get verifyAccount;

  /// Privacy screen title
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// Privacy settings description
  ///
  /// In en, this message translates to:
  /// **'Control your privacy settings'**
  String get privacyDescription;

  /// Safety and security menu item
  ///
  /// In en, this message translates to:
  /// **'Safety & Security'**
  String get safetyAndSecurity;

  /// Safety settings description
  ///
  /// In en, this message translates to:
  /// **'Manage blocked users and safety settings'**
  String get manageSafety;

  /// App preferences section
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get appPreferences;

  /// Language settings menu item
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language settings description
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get chooseLanguage;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Notification settings description
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get manageNotifications;

  /// Theme settings menu item
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Theme settings description
  ///
  /// In en, this message translates to:
  /// **'Choose light or dark theme'**
  String get themeDescription;

  /// Running preferences section
  ///
  /// In en, this message translates to:
  /// **'Running Preferences'**
  String get runningPreferences;

  /// Preferred times menu item
  ///
  /// In en, this message translates to:
  /// **'Preferred Times'**
  String get preferredTimes;

  /// Preferred times description
  ///
  /// In en, this message translates to:
  /// **'Set your preferred running times'**
  String get setPreferredTimes;

  /// Pace and distance menu item
  ///
  /// In en, this message translates to:
  /// **'Pace & Distance'**
  String get paceAndDistance;

  /// Running preferences description
  ///
  /// In en, this message translates to:
  /// **'Configure your running preferences'**
  String get configureRunning;

  /// Safety screen title
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// Emergency contacts menu item
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// Emergency contacts description
  ///
  /// In en, this message translates to:
  /// **'Manage emergency contact information'**
  String get manageEmergencyContacts;

  /// Location sharing menu item
  ///
  /// In en, this message translates to:
  /// **'Location Sharing'**
  String get locationSharing;

  /// Location sharing description
  ///
  /// In en, this message translates to:
  /// **'Control location sharing settings'**
  String get controlLocationSharing;

  /// Safety guidelines menu item
  ///
  /// In en, this message translates to:
  /// **'Safety Guidelines'**
  String get safetyGuidelines;

  /// Safety guidelines description
  ///
  /// In en, this message translates to:
  /// **'Learn important safety tips'**
  String get learnSafetyTips;

  /// About section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// App version menu item
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// Help and support menu item
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// Help and support description
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get getHelp;

  /// Privacy policy menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Privacy policy description
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacyPolicy;

  /// Title for nearby runs section
  ///
  /// In en, this message translates to:
  /// **'Nearby Runs'**
  String get nearbyRuns;

  /// Message shown when user is not signed in
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view nearby runs'**
  String get pleaseSignIn;

  /// Filters button text
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Filter button
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Button to create a new run
  ///
  /// In en, this message translates to:
  /// **'Create Run'**
  String get createRun;

  /// Button to join a run
  ///
  /// In en, this message translates to:
  /// **'Join Run'**
  String get joinRun;

  /// Button to leave a run
  ///
  /// In en, this message translates to:
  /// **'Leave Run'**
  String get leaveRun;

  /// Label for run title input
  ///
  /// In en, this message translates to:
  /// **'Run Title'**
  String get runTitle;

  /// Label for run description input
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get runDescription;

  /// Label for date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Label for time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Label for location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Label for distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Label for pace
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get pace;

  /// Label for difficulty level
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// Beginner difficulty level
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// Intermediate difficulty level
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// Advanced difficulty level
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// Label for run type
  ///
  /// In en, this message translates to:
  /// **'Run Type'**
  String get runType;

  /// Easy run type
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// Tempo run type
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get tempo;

  /// Intervals run type
  ///
  /// In en, this message translates to:
  /// **'Intervals'**
  String get intervals;

  /// Long run type
  ///
  /// In en, this message translates to:
  /// **'Long Run'**
  String get longRun;

  /// Fartlek run type
  ///
  /// In en, this message translates to:
  /// **'Fartlek'**
  String get fartlek;

  /// Label for maximum participants
  ///
  /// In en, this message translates to:
  /// **'Max Participants'**
  String get maxParticipants;

  /// Label for participants
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// Shows current participants vs maximum
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} participants'**
  String participantsCount(int count, int max);

  /// Shows available spots
  ///
  /// In en, this message translates to:
  /// **'{count} spots available'**
  String spotsAvailable(int count);

  /// Indicates the run is full
  ///
  /// In en, this message translates to:
  /// **'Run Full'**
  String get runFull;

  /// Label for waitlist
  ///
  /// In en, this message translates to:
  /// **'Waitlist'**
  String get waitlist;

  /// Button to join waitlist
  ///
  /// In en, this message translates to:
  /// **'Join Waitlist'**
  String get joinWaitlist;

  /// Button to leave waitlist
  ///
  /// In en, this message translates to:
  /// **'Leave Waitlist'**
  String get leaveWaitlist;

  /// Chat screen title
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Placeholder for message input
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Send button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Search action
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Refresh action
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Message when no runs are found
  ///
  /// In en, this message translates to:
  /// **'No runs found'**
  String get noRunsFound;

  /// Description when no runs are found
  ///
  /// In en, this message translates to:
  /// **'There are no runs in your area yet. Be the first to create one!'**
  String get noRunsFoundDescription;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// Try again button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Network error title
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// Network error description
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get networkErrorDescription;

  /// Location permission error title
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionRequired;

  /// Location permission error description
  ///
  /// In en, this message translates to:
  /// **'Please enable location access to find nearby runs.'**
  String get locationPermissionDescription;

  /// Emergency screen title
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// Report user action
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser;

  /// Block user action
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// Phone verification title
  ///
  /// In en, this message translates to:
  /// **'Phone Verification'**
  String get phoneVerification;

  /// Email verification title
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// Strava connection title
  ///
  /// In en, this message translates to:
  /// **'Strava Connection'**
  String get stravaConnection;

  /// Emergency contact title
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// Emergency contact name label
  ///
  /// In en, this message translates to:
  /// **'Contact Name'**
  String get emergencyContactName;

  /// Emergency contact phone label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get emergencyContactPhone;

  /// SOS button text
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosButton;

  /// Emergency alert title
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert'**
  String get emergencyAlert;

  /// Yes confirmation
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No confirmation
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Sign out action
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Sign in action
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Get started button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous button
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Kilometer unit
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmUnit;

  /// Minutes per kilometer unit
  ///
  /// In en, this message translates to:
  /// **'min/km'**
  String get minPerKm;

  /// Today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// This week
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Morning time period
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// Afternoon time period
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// Evening time period
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
