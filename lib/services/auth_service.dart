import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(firestoreServiceProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

final currentUserProvider = StreamProvider<UserProfile?>((ref) {
  final authService = ref.read(authServiceProvider);
  return authService.currentUserStream;
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService;

  AuthService(this._firestoreService);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Stream<UserProfile?> get currentUserStream async* {
    await for (final user in authStateChanges) {
      if (user != null) {
        try {
          // Add a small delay to ensure authentication is fully established
          await Future.delayed(const Duration(milliseconds: 100));
          yield* _firestoreService.getUserProfile(user.uid);
        } catch (e) {
          print('Error getting user profile: $e');
          // Yield null on error but don't break the stream
          yield null;
        }
      } else {
        yield null;
      }
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      // Check if anonymous auth is enabled first
      final credential = await _auth.signInAnonymously();
      
      if (credential.user != null) {
        try {
          await _createUserProfile(credential.user!);
          await _saveAuthState();
        } catch (profileError) {
          // Even if profile creation fails, authentication succeeded
          print('Profile creation error: $profileError');
          await _saveAuthState();
        }
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw AuthException('Anonymous authentication is not enabled. Please enable it in Firebase Console.');
      }
      throw AuthException._fromFirebaseException(e);
    } catch (e) {
      // Handle the PigeonUserDetails type error specifically
      if (e.toString().contains('PigeonUserDetails')) {
        throw AuthException('Firebase authentication plugin error. Please check your Firebase configuration and try restarting the app.');
      }
      throw AuthException('Authentication failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _clearAuthState();
    } on FirebaseAuthException catch (e) {
      throw AuthException._fromFirebaseException(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        await _firestoreService.deleteUserProfile(user.uid);
        await user.delete();
        await _clearAuthState();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException._fromFirebaseException(e);
    }
  }

  Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey('user_onboarded');
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_onboarded', true);
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    RunningPreferences? runningPreferences,
    NotificationSettings? notificationSettings,
    PrivacySettings? privacySettings,
    SafetySettings? safetySettings,
  }) async {
    final user = currentUser;
    if (user == null) throw AuthException('No authenticated user');

    final currentProfile = await _firestoreService.getUserProfileOnce(user.uid);
    if (currentProfile == null) throw AuthException('User profile not found');

    final updatedProfile = currentProfile.copyWith(
      displayName: displayName,
      bio: bio,
      runningPreferences: runningPreferences,
      notificationSettings: notificationSettings,
      privacySettings: privacySettings,
      safetySettings: safetySettings,
      lastActive: DateTime.now(),
    );

    await _firestoreService.updateUserProfile(updatedProfile);
  }

  Future<void> _createUserProfile(User user) async {
    final existingProfile = await _firestoreService.getUserProfileOnce(user.uid);
    
    if (existingProfile == null) {
      final profile = UserProfile(
        uid: user.uid,
        displayName: 'Runner ${user.uid.substring(0, 8)}',
        email: user.email,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        runningPreferences: const RunningPreferences(),
        notificationSettings: const NotificationSettings(),
        privacySettings: const PrivacySettings(),
        safetySettings: const SafetySettings(),
      );

      await _firestoreService.createUserProfile(profile);
    } else {
      final updatedProfile = existingProfile.copyWith(
        lastActive: DateTime.now(),
      );
      await _firestoreService.updateUserProfile(updatedProfile);
    }
  }

  Future<void> _saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_authenticated', true);
  }

  Future<void> _clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_authenticated');
    await prefs.remove('user_onboarded');
  }

  Future<bool> hasExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_authenticated') ?? false;
  }
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, [this.code]);

  factory AuthException._fromFirebaseException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Please try again later.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed.';
        break;
      default:
        message = e.message ?? 'Authentication error occurred.';
    }
    return AuthException(message, e.code);
  }

  @override
  String toString() => message;
}