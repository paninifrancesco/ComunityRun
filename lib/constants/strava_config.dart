/// Strava OAuth2 Configuration
/// 
/// To enable Strava authentication, you need to:
/// 1. Create a Strava app at https://developers.strava.com/
/// 2. Replace the placeholder values below with your actual app credentials
/// 3. Set up URL scheme handling for the redirect URI
/// 
/// IMPORTANT: Never commit real credentials to version control!
/// Consider using environment variables or a separate config file.

import 'package:flutter/foundation.dart';

class StravaConfig {
  // TODO: Replace with your actual Strava app credentials
  // These are placeholder values - replace with your real Strava app credentials
  static const String clientId = '75862';
  static const String clientSecret = '97affdfd17cc631ea698d30b12e1b2756e363c2d';
  
  // The redirect URI registered in your Strava app
  // Updated for mobile app deep linking per 2025 guidelines
  static const String redirectUri = 'communityrun://strava-callback';
  
  // Strava OAuth2 scopes - what permissions your app requests
  // Updated scopes per 2025 API recommendations
  static const List<String> scopes = [
    'read',                  // Read public profile information
    'profile:read_all',      // Read comprehensive profile information
    'activity:read',         // Read basic activity data (recommended over activity:read_all)
  ];
  
  // Check if Strava credentials are properly configured
  static bool get isConfigured {
    final bool configured = clientId != 'YOUR_ACTUAL_CLIENT_ID_HERE' && 
           clientSecret != 'YOUR_ACTUAL_CLIENT_SECRET_HERE' &&
           clientId.isNotEmpty && 
           clientSecret.isNotEmpty;
    
    // Debug logging for configuration status
    if (kDebugMode) {
      print('🔵 [STRAVA CONFIG] Configuration check:');
      print('🔵 [STRAVA CONFIG] Client ID is not placeholder: ${clientId != '75862'}');
      print('🔵 [STRAVA CONFIG] Client Secret is not placeholder: ${clientSecret != '97affdfd17cc631ea698d30b12e1b2756e363c2d'}');
      print('🔵 [STRAVA CONFIG] Client ID not empty: ${clientId.isNotEmpty}');
      print('🔵 [STRAVA CONFIG] Client Secret not empty: ${clientSecret.isNotEmpty}');
      print('🔵 [STRAVA CONFIG] Overall configured: $configured');
      if (!configured) {
        print('❌ [STRAVA CONFIG] Strava is NOT properly configured!');
        print('❌ [STRAVA CONFIG] Please update the credentials in StravaConfig');
      }
    }
    
    return configured;
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
///      * Authorization Callback Domain: localhost
///    - After creating, note down your Client ID and Client Secret
/// 
/// 2. UPDATE CONFIGURATION:
///    - Replace 'YOUR_STRAVA_CLIENT_ID' with your actual Client ID
///    - Replace 'YOUR_STRAVA_CLIENT_SECRET' with your actual Client Secret
///    - Update the placeholders in the StravaConfig class above
/// 
/// 3. AUTHENTICATION FLOW:
///    - User taps "Continue with Strava" 
///    - App opens Strava authorization in browser
///    - User authorizes the app in Strava
///    - Strava redirects to localhost with authorization code
///    - User copies the code from the browser URL
///    - User pastes the code in the app dialog
///    - App exchanges code for access token and completes sign-in
/// 
/// 4. MANUAL CODE ENTRY:
///    After Strava authorization, the browser will redirect to:
///    http://localhost/?code=AUTHORIZATION_CODE&scope=...
///    
///    Users should copy the AUTHORIZATION_CODE part and paste it
///    into the app's code entry dialog.