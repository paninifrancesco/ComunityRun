/// Strava OAuth2 Configuration
/// 
/// To enable Strava authentication, you need to:
/// 1. Create a Strava app at https://developers.strava.com/
/// 2. Replace the placeholder values below with your actual app credentials
/// 3. Set up URL scheme handling for the redirect URI
/// 
/// IMPORTANT: Never commit real credentials to version control!
/// Consider using environment variables or a separate config file.

class StravaConfig {
  // TODO: Replace with your actual Strava app credentials
  static const String clientId = 'YOUR_STRAVA_CLIENT_ID';
  static const String clientSecret = 'YOUR_STRAVA_CLIENT_SECRET';
  
  // The redirect URI registered in your Strava app
  // This should match the URL scheme configured in your app
  static const String redirectUri = 'communityrun://strava-callback';
  
  // Strava OAuth2 scopes - what permissions your app requests
  static const List<String> scopes = [
    'read',                  // Read public profile information
    'activity:read_all',     // Read all activity data  
    'profile:read_all',      // Read profile information
  ];
  
  // Check if Strava credentials are properly configured
  static bool get isConfigured {
    return clientId != 'YOUR_STRAVA_CLIENT_ID' && 
           clientSecret != 'YOUR_STRAVA_CLIENT_SECRET' &&
           clientId.isNotEmpty && 
           clientSecret.isNotEmpty;
  }
}

/// Instructions for setting up Strava authentication:
/// 
/// 1. STRAVA APP SETUP:
///    - Go to https://developers.strava.com/
///    - Click "Create App"
///    - Fill in your app details:
///      * Application Name: CommunityRun
///      * Category: Social Network
///      * Club: (optional)
///      * Website: Your app website
///      * Application Description: Running community app
///      * Authorization Callback Domain: communityrun://strava-callback
///    - After creating, note down your Client ID and Client Secret
/// 
/// 2. UPDATE CONFIGURATION:
///    - Replace 'YOUR_STRAVA_CLIENT_ID' with your actual Client ID
///    - Replace 'YOUR_STRAVA_CLIENT_SECRET' with your actual Client Secret
/// 
/// 3. URL SCHEME SETUP (Android):
///    Add to android/app/src/main/AndroidManifest.xml inside <activity> tag:
///    
///    <intent-filter android:autoVerify="true">
///        <action android:name="android.intent.action.VIEW" />
///        <category android:name="android.intent.category.DEFAULT" />
///        <category android:name="android.intent.category.BROWSABLE" />
///        <data android:scheme="communityrun" android:host="strava-callback" />
///    </intent-filter>
/// 
/// 4. URL SCHEME SETUP (iOS):
///    Add to ios/Runner/Info.plist:
///    
///    <key>CFBundleURLTypes</key>
///    <array>
///        <dict>
///            <key>CFBundleURLName</key>
///            <string>communityrun.strava</string>
///            <key>CFBundleURLSchemes</key>
///            <array>
///                <string>communityrun</string>
///            </array>
///        </dict>
///    </array>
/// 
/// 5. HANDLE DEEP LINKS:
///    The app will automatically handle the callback URL when users
///    return from Strava authorization.