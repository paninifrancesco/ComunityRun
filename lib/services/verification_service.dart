import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_profile.dart';
import 'user_profile_service.dart';

final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService(ref.read(userProfileServiceProvider));
});

class VerificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserProfileService _userProfileService;

  VerificationService(this._userProfileService);

  Future<bool> verifyPhoneNumber(String phoneNumber) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await currentUser.linkWithCredential(credential);
          await _markPhoneAsVerified(currentUser.uid, phoneNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
        },
        codeAutoRetrievalTimeout: (String verificationId) {
        },
      );
      
      return true;
    } catch (e) {
      print('Phone verification error: $e');
      return false;
    }
  }

  Future<bool> verifyPhoneCode(String verificationId, String smsCode) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await currentUser.linkWithCredential(credential);
      await _markPhoneAsVerified(currentUser.uid, currentUser.phoneNumber!);
      
      return true;
    } catch (e) {
      print('Phone code verification error: $e');
      return false;
    }
  }

  Future<bool> verifyWithStrava(String stravaCode) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final stravaProfile = await _exchangeStravaCode(stravaCode);
      if (stravaProfile == null) return false;

      final userProfile = await _userProfileService.getUserProfileOnce(currentUser.uid);
      if (userProfile != null) {
        final updatedProfile = userProfile.copyWith(
          stravaUserId: stravaProfile['id'].toString(),
          isStravaVerified: true,
        );
        await _userProfileService.updateUserProfile(updatedProfile);
      }

      return true;
    } catch (e) {
      print('Strava verification error: $e');
      return false;
    }
  }

  Future<String?> getStravaAuthUrl() async {
    const clientId = 'YOUR_STRAVA_CLIENT_ID'; // Replace with actual client ID
    const redirectUri = 'https://your-app.com/strava-callback'; // Replace with actual redirect URI
    const scope = 'read,activity:read_all';
    
    return 'https://www.strava.com/oauth/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&approval_prompt=force&scope=$scope';
  }

  Future<Map<String, dynamic>?> _exchangeStravaCode(String code) async {
    try {
      const clientId = 'YOUR_STRAVA_CLIENT_ID'; // Replace with actual client ID
      const clientSecret = 'YOUR_STRAVA_CLIENT_SECRET'; // Replace with actual client secret
      
      final response = await http.post(
        Uri.parse('https://www.strava.com/oauth/token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['athlete'];
      }
      
      return null;
    } catch (e) {
      print('Strava code exchange error: $e');
      return null;
    }
  }

  Future<void> _markPhoneAsVerified(String uid, String phoneNumber) async {
    final userProfile = await _userProfileService.getUserProfileOnce(uid);
    if (userProfile != null) {
      final updatedProfile = userProfile.copyWith(
        phoneNumber: phoneNumber,
        isPhoneVerified: true,
      );
      await _userProfileService.updateUserProfile(updatedProfile);
    }
  }

  Future<bool> verifyEmail() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      if (!currentUser.emailVerified) {
        await currentUser.sendEmailVerification();
        return false; // Email sent, but not yet verified
      }

      // If email is verified, update profile
      final userProfile = await _userProfileService.getUserProfileOnce(currentUser.uid);
      if (userProfile != null) {
        final updatedProfile = userProfile.copyWith(
          isEmailVerified: true,
        );
        await _userProfileService.updateUserProfile(updatedProfile);
      }

      return true;
    } catch (e) {
      print('Email verification error: $e');
      return false;
    }
  }

  Future<void> checkEmailVerificationStatus() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await currentUser.reload();
      if (currentUser.emailVerified) {
        final userProfile = await _userProfileService.getUserProfileOnce(currentUser.uid);
        if (userProfile != null) {
          final updatedProfile = userProfile.copyWith(
            isEmailVerified: true,
          );
          await _userProfileService.updateUserProfile(updatedProfile);
        }
      }
    } catch (e) {
      print('Check email verification status error: $e');
    }
  }

  Future<Map<String, bool>> getVerificationStatus(String uid) async {
    try {
      final userProfile = await _userProfileService.getUserProfile(uid).first;
      return {
        'phone': userProfile?.isPhoneVerified ?? false,
        'email': userProfile?.isEmailVerified ?? false,
        'strava': userProfile?.isStravaVerified ?? false,
      };
    } catch (e) {
      print('Get verification status error: $e');
      return {
        'phone': false,
        'email': false,
        'strava': false,
      };
    }
  }
}