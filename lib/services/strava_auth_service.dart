import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../constants/strava_config.dart';
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
  
  // Strava OAuth2 endpoints
  static const String _authorizationEndpoint = 'https://www.strava.com/oauth/authorize';
  static const String _tokenEndpoint = 'https://www.strava.com/oauth/token';
  static const String _apiBaseUrl = 'https://www.strava.com/api/v3';

  StravaAuthService(this._authService, this._firestoreService);

  /// Get Strava authorization URL for OAuth2 flow  
  String getAuthorizationUrl() {
    // Check if Strava is properly configured
    if (!StravaConfig.isConfigured) {
      throw Exception('Strava credentials not configured. Please update StravaConfig.');
    }
    
    final scopes = StravaConfig.scopes;
    
    final uri = Uri.parse(_authorizationEndpoint).replace(queryParameters: {
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'response_type': 'code',
      'approval_prompt': 'force',
      'scope': scopes.join(','),
      'state': DateTime.now().millisecondsSinceEpoch.toString(), // CSRF protection
    });
    
    return uri.toString();
  }

  /// Launch Strava OAuth2 authorization in browser
  Future<bool> launchStravaAuth() async {
    try {
      final authUrl = getAuthorizationUrl();
      final uri = Uri.parse(authUrl);
      
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Open in external browser
        );
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error launching Strava auth: $e');
      }
      return false;
    }
  }

  /// Handle the callback from Strava OAuth2 and complete authentication
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

      // Exchange authorization code for access token
      final tokenResponse = await _exchangeCodeForToken(code);
      if (tokenResponse == null) {
        return StravaAuthResult.error('Failed to exchange code for token');
      }

      // Get Strava athlete profile
      final stravaProfile = await _getStravaProfile(tokenResponse['access_token']);
      if (stravaProfile == null) {
        return StravaAuthResult.error('Failed to get Strava profile');
      }

      // Create or update user in Firebase
      final firebaseUser = await _createOrUpdateFirebaseUser(stravaProfile, tokenResponse);
      if (firebaseUser == null) {
        return StravaAuthResult.error('Failed to create Firebase user');
      }

      return StravaAuthResult.success(firebaseUser);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error handling Strava callback: $e');
      }
      return StravaAuthResult.error('Authentication error: ${e.toString()}');
    }
  }

  /// Exchange authorization code for access token
  Future<Map<String, dynamic>?> _exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if (kDebugMode) {
          print('Token exchange failed: ${response.statusCode} ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error exchanging code for token: $e');
      }
      return null;
    }
  }

  /// Get Strava athlete profile using access token
  Future<Map<String, dynamic>?> _getStravaProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/athlete'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if (kDebugMode) {
          print('Get Strava profile failed: ${response.statusCode} ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting Strava profile: $e');
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
      // Sign in anonymously to Firebase first (as primary auth)
      final credential = await _authService.signInAnonymously();
      if (credential?.user == null) {
        return null;
      }

      final firebaseUser = credential!.user!;
      
      // Create comprehensive user profile with Strava data
      final userProfile = UserProfile(
        uid: firebaseUser.uid,
        displayName: stravaProfile['firstname'] != null && stravaProfile['lastname'] != null
            ? '${stravaProfile['firstname']} ${stravaProfile['lastname']}'
            : stravaProfile['username'] ?? 'Strava Runner',
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

      // Save to Firestore
      await _firestoreService.createUserProfile(userProfile);
      
      // Save Strava tokens securely
      await _saveStravaTokens(tokenData);

      return userProfile;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error creating Firebase user with Strava data: $e');
      }
      return null;
    }
  }

  /// Save Strava tokens securely
  Future<void> _saveStravaTokens(Map<String, dynamic> tokenData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('strava_access_token', tokenData['access_token']);
      await prefs.setString('strava_refresh_token', tokenData['refresh_token']);
      await prefs.setInt('strava_expires_at', tokenData['expires_at']);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving Strava tokens: $e');
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
  Future<Map<String, dynamic>?> refreshAccessToken() async {
    try {
      final tokens = await getSavedStravaTokens();
      if (tokens == null) return null;

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': tokens['refresh_token'],
          'grant_type': 'refresh_token',
        }),
      );

      if (response.statusCode == 200) {
        final newTokens = json.decode(response.body);
        await _saveStravaTokens(newTokens);
        return newTokens;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing Strava token: $e');
      }
      return null;
    }
  }

  /// Check if user has valid Strava connection
  Future<bool> isStravaConnected() async {
    final tokens = await getSavedStravaTokens();
    if (tokens == null) return false;
    
    final expiresAt = tokens['expires_at'];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    return expiresAt > now;
  }

  /// Disconnect Strava account
  Future<void> disconnectStrava() async {
    try {
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