import 'package:flutter/foundation.dart';
import '../constants/strava_config.dart';

/// Helper class for debugging Strava authentication issues
class StravaDebugHelper {
  
  /// Print comprehensive debug information about Strava configuration
  static void printConfigurationStatus() {
    if (!kDebugMode) return;
    
    print('');
    print('🔍 [STRAVA DEBUG HELPER] ===== CONFIGURATION STATUS =====');
    print('🔵 [STRAVA DEBUG HELPER] Client ID: ${StravaConfig.clientId}');
    print('🔵 [STRAVA DEBUG HELPER] Client Secret: ${StravaConfig.clientSecret.substring(0, 10)}...');
    print('🔵 [STRAVA DEBUG HELPER] Redirect URI: ${StravaConfig.redirectUri}');
    print('🔵 [STRAVA DEBUG HELPER] Scopes: ${StravaConfig.scopes.join(', ')}');
    print('🔵 [STRAVA DEBUG HELPER] Is Configured: ${StravaConfig.isConfigured}');
    
    if (!StravaConfig.isConfigured) {
      print('');
      print('❌ [STRAVA DEBUG HELPER] ===== CONFIGURATION ISSUES =====');
      print('❌ [STRAVA DEBUG HELPER] Strava is not properly configured!');
      print('❌ [STRAVA DEBUG HELPER] Please check the following:');
      print('❌ [STRAVA DEBUG HELPER] 1. Update Client ID in StravaConfig');
      print('❌ [STRAVA DEBUG HELPER] 2. Update Client Secret in StravaConfig');
      print('❌ [STRAVA DEBUG HELPER] 3. Ensure they are not placeholder values');
      print('❌ [STRAVA DEBUG HELPER] 4. Check STRAVA_SETUP.md for setup instructions');
    } else {
      print('✅ [STRAVA DEBUG HELPER] Configuration looks good!');
    }
    print('🔍 [STRAVA DEBUG HELPER] =========================================');
    print('');
  }
  
  /// Print troubleshooting tips based on common failure scenarios
  static void printTroubleshootingTips() {
    if (!kDebugMode) return;
    
    print('');
    print('🔧 [STRAVA DEBUG HELPER] ===== TROUBLESHOOTING TIPS =====');
    print('🔧 [STRAVA DEBUG HELPER] Common Strava login failure causes:');
    print('');
    print('🔧 [STRAVA DEBUG HELPER] 1. CONFIGURATION ISSUES:');
    print('🔧 [STRAVA DEBUG HELPER]    - Client ID/Secret not updated from placeholders');
    print('🔧 [STRAVA DEBUG HELPER]    - Wrong redirect URI in Strava app settings');
    print('🔧 [STRAVA DEBUG HELPER]    - App not approved in Strava developer portal');
    print('');
    print('🔧 [STRAVA DEBUG HELPER] 2. NETWORK ISSUES:');
    print('🔧 [STRAVA DEBUG HELPER]    - No internet connection');
    print('🔧 [STRAVA DEBUG HELPER]    - Firewall blocking requests');
    print('🔧 [STRAVA DEBUG HELPER]    - Corporate proxy interfering');
    print('');
    print('🔧 [STRAVA DEBUG HELPER] 3. AUTHORIZATION CODE ISSUES:');
    print('🔧 [STRAVA DEBUG HELPER]    - Invalid/expired authorization code');
    print('🔧 [STRAVA DEBUG HELPER]    - Code used more than once');
    print('🔧 [STRAVA DEBUG HELPER]    - User denied permission in Strava');
    print('');
    print('🔧 [STRAVA DEBUG HELPER] 4. API ENDPOINT ISSUES:');
    print('🔧 [STRAVA DEBUG HELPER]    - Strava API temporarily down');
    print('🔧 [STRAVA DEBUG HELPER]    - Rate limits exceeded');
    print('🔧 [STRAVA DEBUG HELPER]    - Wrong API endpoints/URLs');
    print('');
    print('🔧 [STRAVA DEBUG HELPER] 5. FIREBASE ISSUES:');
    print('🔧 [STRAVA DEBUG HELPER]    - Firebase not initialized');
    print('🔧 [STRAVA DEBUG HELPER]    - Anonymous auth disabled');
    print('🔧 [STRAVA DEBUG HELPER]    - Firestore rules too restrictive');
    print('🔧 [STRAVA DEBUG HELPER] =======================================');
    print('');
  }
  
  /// Validate authorization code format
  static bool validateAuthorizationCode(String code) {
    if (!kDebugMode) return true;
    
    print('');
    print('🔍 [STRAVA DEBUG HELPER] ===== VALIDATING AUTH CODE =====');
    print('🔵 [STRAVA DEBUG HELPER] Code length: ${code.length}');
    print('🔵 [STRAVA DEBUG HELPER] Code (first 10 chars): ${code.length > 10 ? code.substring(0, 10) : code}...');
    
    // Basic validation
    final isValid = code.isNotEmpty && 
                   code.length > 10 && 
                   !code.contains(' ') && 
                   RegExp(r'^[a-zA-Z0-9]+$').hasMatch(code);
    
    if (isValid) {
      print('✅ [STRAVA DEBUG HELPER] Authorization code format looks valid');
    } else {
      print('❌ [STRAVA DEBUG HELPER] Authorization code format issues:');
      if (code.isEmpty) print('❌ [STRAVA DEBUG HELPER] - Code is empty');
      if (code.length <= 10) print('❌ [STRAVA DEBUG HELPER] - Code too short (should be longer)');
      if (code.contains(' ')) print('❌ [STRAVA DEBUG HELPER] - Code contains spaces');
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(code)) print('❌ [STRAVA DEBUG HELPER] - Code contains invalid characters');
    }
    
    print('🔍 [STRAVA DEBUG HELPER] ===============================');
    print('');
    
    return isValid;
  }
  
  /// Print step-by-step authentication process
  static void printAuthenticationSteps() {
    if (!kDebugMode) return;
    
    print('');
    print('📋 [STRAVA DEBUG HELPER] ===== AUTHENTICATION STEPS =====');
    print('📋 [STRAVA DEBUG HELPER] Follow these steps to debug:');
    print('📋 [STRAVA DEBUG HELPER] ');
    print('📋 [STRAVA DEBUG HELPER] Step 1: Check configuration');
    print('📋 [STRAVA DEBUG HELPER]   - Look for [STRAVA CONFIG] logs');
    print('📋 [STRAVA DEBUG HELPER]   - Ensure isConfigured = true');
    print('📋 [STRAVA DEBUG HELPER] ');
    print('📋 [STRAVA DEBUG HELPER] Step 2: Launch authorization');
    print('📋 [STRAVA DEBUG HELPER]   - Look for "launchStravaAuth" logs');
    print('📋 [STRAVA DEBUG HELPER]   - Check if URL can be launched');
    print('📋 [STRAVA DEBUG HELPER] ');
    print('📋 [STRAVA DEBUG HELPER] Step 3: Handle authorization code');
    print('📋 [STRAVA DEBUG HELPER]   - Look for "handleAuthorizationCode" logs');
    print('📋 [STRAVA DEBUG HELPER]   - Check code format and length');
    print('📋 [STRAVA DEBUG HELPER] ');
    print('📋 [STRAVA DEBUG HELPER] Step 4: Exchange code for token');
    print('📋 [STRAVA DEBUG HELPER]   - Look for "_exchangeCodeForToken" logs');
    print('📋 [STRAVA DEBUG HELPER]   - Check HTTP response status and body');
    print('📋 [STRAVA DEBUG HELPER] ');
    print('📋 [STRAVA DEBUG HELPER] Step 5: Get Strava profile');
    print('📋 [STRAVA DEBUG HELPER]   - Look for "_getStravaProfile" logs');
    print('📋 [STRAVA DEBUG HELPER]   - Check profile data received');
    print('📋 [STRAVA DEBUG HELPER] ');
    print('📋 [STRAVA DEBUG HELPER] Step 6: Create Firebase user');
    print('📋 [STRAVA DEBUG HELPER]   - Look for "_createOrUpdateFirebaseUser" logs');
    print('📋 [STRAVA DEBUG HELPER]   - Check Firebase authentication and Firestore');
    print('📋 [STRAVA DEBUG HELPER] =====================================');
    print('');
  }
}