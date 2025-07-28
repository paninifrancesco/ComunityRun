// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CommunityRun';

  @override
  String get home => 'Home';

  @override
  String get discover => 'Discover';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get manageProfile => 'Manage your profile information';

  @override
  String get verification => 'Verification';

  @override
  String get verifyAccount => 'Verify your account';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyDescription => 'Control your privacy settings';

  @override
  String get safetyAndSecurity => 'Safety & Security';

  @override
  String get manageSafety => 'Manage blocked users and safety settings';

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose your preferred language';

  @override
  String get notifications => 'Notifications';

  @override
  String get manageNotifications => 'Manage notification preferences';

  @override
  String get theme => 'Theme';

  @override
  String get themeDescription => 'Choose light or dark theme';

  @override
  String get runningPreferences => 'Running Preferences';

  @override
  String get preferredTimes => 'Preferred Times';

  @override
  String get setPreferredTimes => 'Set your preferred running times';

  @override
  String get paceAndDistance => 'Pace & Distance';

  @override
  String get configureRunning => 'Configure your running preferences';

  @override
  String get safety => 'Safety';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get manageEmergencyContacts => 'Manage emergency contact information';

  @override
  String get locationSharing => 'Location Sharing';

  @override
  String get controlLocationSharing => 'Control location sharing settings';

  @override
  String get safetyGuidelines => 'Safety Guidelines';

  @override
  String get learnSafetyTips => 'Learn important safety tips';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'App Version';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get getHelp => 'Get help and support';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get readPrivacyPolicy => 'Read our privacy policy';

  @override
  String get nearbyRuns => 'Nearby Runs';

  @override
  String get pleaseSignIn => 'Please sign in to view nearby runs';

  @override
  String get filters => 'Filters';

  @override
  String get filter => 'Filter';

  @override
  String get createRun => 'Create Run';

  @override
  String get joinRun => 'Join Run';

  @override
  String get leaveRun => 'Leave Run';

  @override
  String get runTitle => 'Run Title';

  @override
  String get runDescription => 'Description';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get location => 'Location';

  @override
  String get distance => 'Distance';

  @override
  String get pace => 'Pace';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get runType => 'Run Type';

  @override
  String get easy => 'Easy';

  @override
  String get tempo => 'Tempo';

  @override
  String get intervals => 'Intervals';

  @override
  String get longRun => 'Long Run';

  @override
  String get fartlek => 'Fartlek';

  @override
  String get maxParticipants => 'Max Participants';

  @override
  String get participants => 'Participants';

  @override
  String participantsCount(int count, int max) {
    return '$count / $max participants';
  }

  @override
  String spotsAvailable(int count) {
    return '$count spots available';
  }

  @override
  String get runFull => 'Run Full';

  @override
  String get waitlist => 'Waitlist';

  @override
  String get joinWaitlist => 'Join Waitlist';

  @override
  String get leaveWaitlist => 'Leave Waitlist';

  @override
  String get chat => 'Chat';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get refresh => 'Refresh';

  @override
  String get loading => 'Loading...';

  @override
  String get noRunsFound => 'No runs found';

  @override
  String get noRunsFoundDescription =>
      'There are no runs in your area yet. Be the first to create one!';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get networkError => 'Network Error';

  @override
  String get networkErrorDescription =>
      'Please check your internet connection and try again.';

  @override
  String get locationPermissionRequired => 'Location Permission Required';

  @override
  String get locationPermissionDescription =>
      'Please enable location access to find nearby runs.';

  @override
  String get emergency => 'Emergency';

  @override
  String get reportUser => 'Report User';

  @override
  String get blockUser => 'Block User';

  @override
  String get phoneVerification => 'Phone Verification';

  @override
  String get emailVerification => 'Email Verification';

  @override
  String get stravaConnection => 'Strava Connection';

  @override
  String get emergencyContact => 'Emergency Contact';

  @override
  String get emergencyContactName => 'Contact Name';

  @override
  String get emergencyContactPhone => 'Phone Number';

  @override
  String get sosButton => 'SOS';

  @override
  String get emergencyAlert => 'Emergency Alert';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signIn => 'Sign In';

  @override
  String get welcome => 'Welcome';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get skip => 'Skip';

  @override
  String get done => 'Done';

  @override
  String get kmUnit => 'km';

  @override
  String get minPerKm => 'min/km';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeek => 'This Week';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';
}
