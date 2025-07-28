import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../constants/strava_config.dart';
import '../utils/strava_debug_helper.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

final stravaAuthServiceProvider = Provider<StravaAuthService>((ref) {
  return StravaAuthService(
    ref.read(authServiceProvider),
    ref.read(firestoreServiceProvider),
  );
});

class StravaAuthService {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  
  // Get credentials from configuration
  static String get _clientId => StravaConfig.clientId;
  static String get _clientSecret => StravaConfig.clientSecret;
  static String get _redirectUri => StravaConfig.redirectUri;
  
  // Strava OAuth2 endpoints (Updated 2025)
  static const String _authorizationEndpoint = 'https://www.strava.com/oauth/authorize';
  static const String _mobileAuthorizationEndpoint = 'https://www.strava.com/oauth/mobile/authorize';
  static const String _tokenEndpoint = 'https://www.strava.com/oauth/token';
  static const String _deauthorizeEndpoint = 'https://www.strava.com/oauth/deauthorize';
  static const String _apiBaseUrl = 'https://www.strava.com/api/v3';

  StravaAuthService(this._authService, this._firestoreService);

  /// Get Strava authorization URL for OAuth2 flow
  /// [isMobile] - Use mobile-optimized endpoint for better mobile experience
  String getAuthorizationUrl({bool isMobile = true}) {
    if (kDebugMode) {
      print('🔵 [STRAVA DEBUG] Starting getAuthorizationUrl');
      print('🔵 [STRAVA DEBUG] isMobile: $isMobile');
      print('🔵 [STRAVA DEBUG] StravaConfig.isConfigured: ${StravaConfig.isConfigured}');
      print('🔵 [STRAVA DEBUG] Client ID: ${_clientId.substring(0, 5)}...');
      print('🔵 [STRAVA DEBUG] Redirect URI: $_redirectUri');
    }
    
    // Check if Strava is properly configured
    if (!StravaConfig.isConfigured) {
      if (kDebugMode) {
        print('❌ [STRAVA DEBUG] Strava credentials not configured!');
      }
      throw Exception('Strava credentials not configured. Please update StravaConfig.');
    }
    
    final scopes = StravaConfig.scopes;
    final endpoint = isMobile ? _mobileAuthorizationEndpoint : _authorizationEndpoint;
    
    if (kDebugMode) {
      print('🔵 [STRAVA DEBUG] Using endpoint: $endpoint');
      print('🔵 [STRAVA DEBUG] Scopes: ${scopes.join(',')}');
    }
    
    final uri = Uri.parse(endpoint).replace(queryParameters: {
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'response_type': 'code',
      'approval_prompt': 'auto', // Changed from 'force' to 'auto' per 2025 guidelines
      'scope': scopes.join(','),
      'state': DateTime.now().millisecondsSinceEpoch.toString(), // CSRF protection
    });
    
    final authUrl = uri.toString();
    if (kDebugMode) {
      print('🔵 [STRAVA DEBUG] Generated auth URL: ${authUrl.substring(0, 100)}...');
    }
    
    return authUrl;
  }

  /// Launch Strava OAuth2 authorization
  /// Uses mobile-optimized flow for better user experience
  Future<String?> launchStravaAuth({bool preferStravaApp = true}) async {
    try {
      // Print debug configuration and troubleshooting info
      StravaDebugHelper.printConfigurationStatus();
      StravaDebugHelper.printAuthenticationSteps();
      
      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] Starting launchStravaAuth');
        print('🔵 [STRAVA DEBUG] preferStravaApp: $preferStravaApp');
      }
      
      final authUrl = getAuthorizationUrl(isMobile: true);
      final uri = Uri.parse(authUrl);
      
      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] Checking if URL can be launched...');
      }
      
      // Try multiple launch modes for better compatibility
      bool launched = false;
      
      // Method 1: Try external application first (Strava app or browser)
      if (await canLaunchUrl(uri)) {
        try {
          if (kDebugMode) {
            print('🔵 [STRAVA DEBUG] Method 1: Trying external application launch...');
          }
          
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          launched = true;
          
          if (kDebugMode) {
            print('✅ [STRAVA DEBUG] Method 1 SUCCESS: External application launch worked');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ [STRAVA DEBUG] Method 1 FAILED: External application launch failed: $e');
          }
        }
      }
      
      // Method 2: Try in-app web view as fallback
      if (!launched) {
        try {
          if (kDebugMode) {
            print('🔵 [STRAVA DEBUG] Method 2: Trying in-app web view launch...');
          }
          
          await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
          launched = true;
          
          if (kDebugMode) {
            print('✅ [STRAVA DEBUG] Method 2 SUCCESS: In-app web view launch worked');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ [STRAVA DEBUG] Method 2 FAILED: In-app web view launch failed: $e');
          }
        }
      }
      
      // Method 3: Try platform default as final fallback
      if (!launched) {
        try {
          if (kDebugMode) {
            print('🔵 [STRAVA DEBUG] Method 3: Trying platform default launch...');
          }
          
          await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          launched = true;
          
          if (kDebugMode) {
            print('✅ [STRAVA DEBUG] Method 3 SUCCESS: Platform default launch worked');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ [STRAVA DEBUG] Method 3 FAILED: Platform default launch failed: $e');
          }
        }
      }
      
      if (launched) {
        if (kDebugMode) {
          print('✅ [STRAVA DEBUG] Successfully launched Strava auth URL');
        }
        return authUrl;
      } else {
        if (kDebugMode) {
          print('❌ [STRAVA DEBUG] All launch methods failed - cannot open URL');
          print('❌ [STRAVA DEBUG] This may be due to:');
          print('❌ [STRAVA DEBUG] 1. Missing URL scheme configuration in AndroidManifest.xml');
          print('❌ [STRAVA DEBUG] 2. Missing url_launcher permissions');
          print('❌ [STRAVA DEBUG] 3. Emulator limitations (try on real device)');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [STRAVA DEBUG] Error launching Strava auth: $e');
        print('❌ [STRAVA DEBUG] Stack trace: ${StackTrace.current}');
      }
      return null;
    }
  }

  /// Handle manual authorization code entry from Strava
  Future<StravaAuthResult> handleAuthorizationCode(String authCode) async {
    try {
      // Validate and debug the authorization code
      StravaDebugHelper.validateAuthorizationCode(authCode);
      
      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] Starting handleAuthorizationCode');
        print('🔵 [STRAVA DEBUG] Auth code length: ${authCode.length}');
        print('🔵 [STRAVA DEBUG] Auth code (first 10 chars): ${authCode.length > 10 ? authCode.substring(0, 10) : authCode}...');
      }
      
      if (authCode.trim().isEmpty) {
        if (kDebugMode) {
          print('❌ [STRAVA DEBUG] Authorization code is empty');
        }
        return StravaAuthResult.error('Authorization code cannot be empty');
      }

      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] Step 1: Exchanging authorization code for access token...');
      }
      
      // Exchange authorization code for access token
      final tokenResponse = await _exchangeCodeForToken(authCode.trim());
      if (tokenResponse == null) {
        if (kDebugMode) {
          print('❌ [STRAVA DEBUG] Step 1 FAILED: Token exchange returned null');
        }
        return StravaAuthResult.error('Failed to exchange code for token');
      }

      if (kDebugMode) {
        print('✅ [STRAVA DEBUG] Step 1 SUCCESS: Token exchange completed');
        print('🔵 [STRAVA DEBUG] Token response keys: ${tokenResponse.keys.toList()}');
        print('🔵 [STRAVA DEBUG] Access token (first 10 chars): ${tokenResponse['access_token']?.toString().substring(0, 10)}...');
        print('🔵 [STRAVA DEBUG] Step 2: Getting Strava athlete profile...');
      }

      // Get Strava athlete profile
      final stravaProfile = await _getStravaProfile(tokenResponse['access_token']);
      if (stravaProfile == null) {
        if (kDebugMode) {
          print('❌ [STRAVA DEBUG] Step 2 FAILED: Could not get Strava profile');
        }
        return StravaAuthResult.error('Failed to get Strava profile');
      }

      if (kDebugMode) {
        print('✅ [STRAVA DEBUG] Step 2 SUCCESS: Got Strava profile');
        print('🔵 [STRAVA DEBUG] Profile keys: ${stravaProfile.keys.toList()}');
        print('🔵 [STRAVA DEBUG] Athlete ID: ${stravaProfile['id']}');
        print('🔵 [STRAVA DEBUG] Athlete name: ${stravaProfile['firstname']} ${stravaProfile['lastname']}');
        print('🔵 [STRAVA DEBUG] Step 3: Creating/updating Firebase user...');
      }

      // Create or update user in Firebase
      final firebaseUser = await _createOrUpdateFirebaseUser(stravaProfile, tokenResponse);
      if (firebaseUser == null) {
        if (kDebugMode) {
          print('❌ [STRAVA DEBUG] Step 3 FAILED: Could not create Firebase user');
        }
        return StravaAuthResult.error('Failed to create Firebase user');
      }

      if (kDebugMode) {
        print('✅ [STRAVA DEBUG] Step 3 SUCCESS: Firebase user created/updated');
        print('🔵 [STRAVA DEBUG] Firebase UID: ${firebaseUser.uid}');
        print('✅ [STRAVA DEBUG] ALL STEPS COMPLETED: Authentication successful!');
      }

      return StravaAuthResult.success(firebaseUser);
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ [STRAVA DEBUG] EXCEPTION in handleAuthorizationCode: $e');
        print('❌ [STRAVA DEBUG] Stack trace: ${StackTrace.current}');
        StravaDebugHelper.printTroubleshootingTips();
      }
      return StravaAuthResult.error('Authentication error: ${e.toString()}');
    }
  }

  /// Handle the callback from Strava OAuth2 and complete authentication
  /// Deprecated - use handleAuthorizationCode for manual flow
  Future<StravaAuthResult> handleAuthCallback(String callbackUrl) async {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        return StravaAuthResult.error('Strava authorization failed: $error');
      }
      
      if (code == null) {
        return StravaAuthResult.error('No authorization code received');
      }

      return await handleAuthorizationCode(code);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error handling Strava callback: $e');
      }
      return StravaAuthResult.error('Authentication error: ${e.toString()}');
    }
  }

  /// Exchange authorization code for access token
  /// Updated to use form-encoded data as per 2025 Strava API requirements
  Future<Map<String, dynamic>?> _exchangeCodeForToken(String code) async {
    try {
      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] _exchangeCodeForToken starting...');
        print('🔵 [STRAVA DEBUG] Token endpoint: $_tokenEndpoint');
        print('🔵 [STRAVA DEBUG] Client ID: ${_clientId.substring(0, 5)}...');
        print('🔵 [STRAVA DEBUG] Code length: ${code.length}');
      }

      final requestBody = {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
      };

      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] Request body keys: ${requestBody.keys.toList()}');
        print('🔵 [STRAVA DEBUG] Making POST request to token endpoint...');
      }

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] Response status code: ${response.statusCode}');
        print('🔵 [STRAVA DEBUG] Response headers: ${response.headers}');
        print('🔵 [STRAVA DEBUG] Response body length: ${response.body.length}');
        print('🔵 [STRAVA DEBUG] Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        
        if (kDebugMode) {
          print('✅ [STRAVA DEBUG] Token response parsed successfully');
          print('🔵 [STRAVA DEBUG] Token data keys: ${tokenData.keys.toList()}');
        }
        
        // Validate required fields per 2025 API
        if (tokenData['access_token'] == null || 
            tokenData['refresh_token'] == null ||
            tokenData['expires_at'] == null) {
          if (kDebugMode) {
            print('❌ [STRAVA DEBUG] Invalid token response: missing required fields');
            print('❌ [STRAVA DEBUG] access_token present: ${tokenData['access_token'] != null}');
            print('❌ [STRAVA DEBUG] refresh_token present: ${tokenData['refresh_token'] != null}');
            print('❌ [STRAVA DEBUG] expires_at present: ${tokenData['expires_at'] != null}');
          }
          return null;
        }
        
        if (kDebugMode) {
          print('✅ [STRAVA DEBUG] Token validation successful');
        }
        return tokenData;
      } else {
        if (kDebugMode) {
          print('❌ [STRAVA DEBUG] Token exchange failed with status: ${response.statusCode}');
          print('❌ [STRAVA DEBUG] Error response body: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [STRAVA DEBUG] Exception in _exchangeCodeForToken: $e');
        print('❌ [STRAVA DEBUG] Stack trace: ${StackTrace.current}');
      }
      return null;
    }
  }

  /// Get Strava athlete profile using access token
  Future<Map<String, dynamic>?> _getStravaProfile(String accessToken) async {
    try {
      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] _getStravaProfile starting...');
        print('🔵 [STRAVA DEBUG] API endpoint: $_apiBaseUrl/athlete');
        print('🔵 [STRAVA DEBUG] Access token (first 10 chars): ${accessToken.substring(0, 10)}...');
      }

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/athlete'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] Profile response status: ${response.statusCode}');
        print('🔵 [STRAVA DEBUG] Profile response headers: ${response.headers}');
        print('🔵 [STRAVA DEBUG] Profile response body length: ${response.body.length}');
      }

      if (response.statusCode == 200) {
        final profileData = json.decode(response.body);
        
        if (kDebugMode) {
          print('✅ [STRAVA DEBUG] Profile response parsed successfully');
          print('🔵 [STRAVA DEBUG] Profile data keys: ${profileData.keys.toList()}');
          print('🔵 [STRAVA DEBUG] Athlete firstname: ${profileData['firstname']}');
          print('🔵 [STRAVA DEBUG] Athlete lastname: ${profileData['lastname']}');
          print('🔵 [STRAVA DEBUG] Athlete username: ${profileData['username']}');
          print('🔵 [STRAVA DEBUG] Athlete ID: ${profileData['id']}');
        }
        
        return profileData;
      } else {
        if (kDebugMode) {
          print('❌ [STRAVA DEBUG] Get Strava profile failed with status: ${response.statusCode}');
          print('❌ [STRAVA DEBUG] Profile error response body: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [STRAVA DEBUG] Exception in _getStravaProfile: $e');
        print('❌ [STRAVA DEBUG] Stack trace: ${StackTrace.current}');
      }
      return null;
    }
  }

  /// Create or update Firebase user with Strava data
  Future<UserProfile?> _createOrUpdateFirebaseUser(
    Map<String, dynamic> stravaProfile,
    Map<String, dynamic> tokenData,
  ) async {
    try {
      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] _createOrUpdateFirebaseUser starting...');
        print('🔵 [STRAVA DEBUG] Signing in anonymously to Firebase...');
      }

      // Sign in anonymously to Firebase first (as primary auth)
      final credential = await _authService.signInAnonymously();
      if (credential?.user == null) {
        if (kDebugMode) {
          print('❌ [STRAVA DEBUG] Firebase anonymous sign-in failed');
        }
        return null;
      }

      final firebaseUser = credential!.user!;
      
      if (kDebugMode) {
        print('✅ [STRAVA DEBUG] Firebase anonymous sign-in successful');
        print('🔵 [STRAVA DEBUG] Firebase UID: ${firebaseUser.uid}');
        print('🔵 [STRAVA DEBUG] Creating UserProfile object...');
      }
      
      // Create comprehensive user profile with Strava data
      final displayName = stravaProfile['firstname'] != null && stravaProfile['lastname'] != null
          ? '${stravaProfile['firstname']} ${stravaProfile['lastname']}'
          : stravaProfile['username'] ?? 'Strava Runner';

      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] Display name: $displayName');
        print('🔵 [STRAVA DEBUG] Email: ${stravaProfile['email']}');
        print('🔵 [STRAVA DEBUG] Photo URL: ${stravaProfile['profile_medium'] ?? stravaProfile['profile']}');
      }

      final userProfile = UserProfile(
        uid: firebaseUser.uid,
        displayName: displayName,
        email: stravaProfile['email'],
        photoUrl: stravaProfile['profile_medium'] ?? stravaProfile['profile'],
        bio: stravaProfile['bio'],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        runningPreferences: const RunningPreferences(),
        notificationSettings: const NotificationSettings(),
        privacySettings: const PrivacySettings(),
        safetySettings: const SafetySettings(),
        stravaUserId: stravaProfile['id'].toString(),
        isStravaVerified: true,
        stravaProfile: {
          ...stravaProfile,
          'access_token': tokenData['access_token'],
          'refresh_token': tokenData['refresh_token'],
          'expires_at': tokenData['expires_at'],
          'connected_at': DateTime.now().toIso8601String(),
        },
      );

      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] UserProfile created, saving to Firestore...');
      }

      // Save to Firestore
      await _firestoreService.createUserProfile(userProfile);
      
      if (kDebugMode) {
        print('✅ [STRAVA DEBUG] UserProfile saved to Firestore');
        print('🔵 [STRAVA DEBUG] Saving Strava tokens locally...');
      }
      
      // Save Strava tokens securely
      await _saveStravaTokens(tokenData);

      if (kDebugMode) {
        print('✅ [STRAVA DEBUG] Strava tokens saved locally');
        print('✅ [STRAVA DEBUG] Firebase user creation completed successfully');
      }

      return userProfile;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ [STRAVA DEBUG] Exception in _createOrUpdateFirebaseUser: $e');
        print('❌ [STRAVA DEBUG] Stack trace: ${StackTrace.current}');
      }
      return null;
    }
  }

  /// Save Strava tokens securely
  Future<void> _saveStravaTokens(Map<String, dynamic> tokenData) async {
    try {
      if (kDebugMode) {
        print('🔵 [STRAVA DEBUG] _saveStravaTokens starting...');
        print('🔵 [STRAVA DEBUG] Token data keys to save: ${tokenData.keys.toList()}');
      }

      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('strava_access_token', tokenData['access_token']);
      await prefs.setString('strava_refresh_token', tokenData['refresh_token']);
      await prefs.setInt('strava_expires_at', tokenData['expires_at']);

      if (kDebugMode) {
        print('✅ [STRAVA DEBUG] Tokens saved to SharedPreferences');
        print('🔵 [STRAVA DEBUG] Access token saved: ${tokenData['access_token'] != null}');
        print('🔵 [STRAVA DEBUG] Refresh token saved: ${tokenData['refresh_token'] != null}');
        print('🔵 [STRAVA DEBUG] Expires at saved: ${tokenData['expires_at']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [STRAVA DEBUG] Exception saving Strava tokens: $e');
        print('❌ [STRAVA DEBUG] Stack trace: ${StackTrace.current}');
      }
    }
  }

  /// Get saved Strava tokens
  Future<Map<String, dynamic>?> getSavedStravaTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('strava_access_token');
      final refreshToken = prefs.getString('strava_refresh_token');
      final expiresAt = prefs.getInt('strava_expires_at');

      if (accessToken != null && refreshToken != null && expiresAt != null) {
        return {
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'expires_at': expiresAt,
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting saved Strava tokens: $e');
      }
      return null;
    }
  }

  /// Refresh Strava access token
  /// Updated to use form-encoded data and handle token rotation per 2025 API
  Future<Map<String, dynamic>?> refreshAccessToken() async {
    try {
      final tokens = await getSavedStravaTokens();
      if (tokens == null) return null;

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': tokens['refresh_token'],
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final newTokens = json.decode(response.body);
        
        // Validate token response
        if (newTokens['access_token'] == null) {
          if (kDebugMode) {
            print('Invalid refresh token response: missing access_token');
          }
          return null;
        }
        
        // Always use the most recent refresh token if provided
        if (newTokens['refresh_token'] != null) {
          await _saveStravaTokens(newTokens);
        } else {
          // Some responses may not include a new refresh token
          // In that case, keep the existing refresh token
          newTokens['refresh_token'] = tokens['refresh_token'];
          await _saveStravaTokens(newTokens);
        }
        
        return newTokens;
      } else {
        if (kDebugMode) {
          print('Token refresh failed: ${response.statusCode} ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing Strava token: $e');
      }
      return null;
    }
  }

  /// Check if user has valid Strava connection
  /// Automatically refreshes token if expired but refresh token is available
  Future<bool> isStravaConnected() async {
    try {
      final tokens = await getSavedStravaTokens();
      if (tokens == null) return false;
      
      final expiresAt = tokens['expires_at'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // If token is still valid
      if (expiresAt > now) {
        return true;
      }
      
      // Try to refresh if expired but refresh token exists
      if (tokens['refresh_token'] != null) {
        final refreshedTokens = await refreshAccessToken();
        return refreshedTokens != null;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking Strava connection: $e');
      }
      return false;
    }
  }

  /// Disconnect Strava account
  /// Properly deauthorizes the application on Strava per 2025 API guidelines
  Future<void> disconnectStrava() async {
    try {
      // First try to deauthorize the app on Strava's side
      final tokens = await getSavedStravaTokens();
      if (tokens != null && tokens['access_token'] != null) {
        await _deauthorizeStravaApp(tokens['access_token']);
      }
      
      // Remove local tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('strava_access_token');
      await prefs.remove('strava_refresh_token');
      await prefs.remove('strava_expires_at');
      
      // Update user profile to remove Strava connection
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userProfile = await _firestoreService.getUserProfileOnce(currentUser.uid);
        if (userProfile != null) {
          final updatedProfile = userProfile.copyWith(
            stravaUserId: null,
            isStravaVerified: false,
          );
          await _firestoreService.updateUserProfile(updatedProfile);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disconnecting Strava: $e');
      }
    }
  }

  /// Deauthorize the application on Strava's servers
  Future<void> _deauthorizeStravaApp(String accessToken) async {
    try {
      await http.post(
        Uri.parse(_deauthorizeEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      // Note: Strava deauthorization endpoint may return various status codes
      // We don't need to handle the response as local cleanup is more important
    } catch (e) {
      if (kDebugMode) {
        print('Error deauthorizing Strava app: $e');
      }
      // Continue with local cleanup even if deauthorization fails
    }
  }
}

/// Result class for Strava authentication
class StravaAuthResult {
  final bool isSuccess;
  final String? error;
  final UserProfile? userProfile;

  StravaAuthResult._(this.isSuccess, this.error, this.userProfile);

  factory StravaAuthResult.success(UserProfile userProfile) {
    return StravaAuthResult._(true, null, userProfile);
  }

  factory StravaAuthResult.error(String error) {
    return StravaAuthResult._(false, error, null);
  }
}