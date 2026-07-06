import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fyp_source_code/auth/data/models/signin_model.dart';
import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/services/api_names.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  // For web: set this to your OAuth 2.0 Web Client ID from Google Cloud Console
  // Firebase Console → Project Settings → General → Your apps → Web → Web client ID
  static const String _webClientId = '';

  Future<Map<String, dynamic>> signInWithGoogle({String? username}) async {
    try {
      if (kIsWeb && _webClientId.isEmpty) {
        return {
          'success': false,
          'message': 'Google Sign-In web client ID not configured. Set _webClientId in auth_service.dart',
        };
      }
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? _webClientId : null,
      );
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      if (googleAuth.idToken == null) {
        return {'success': false, 'message': 'Failed to get Google ID token'};
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);

      final Map<String, dynamic> response = await DioHelper().post(
        url: ApiNames.googleLogin,
        reqBody: {
          'idToken': googleAuth.idToken,
          'username': username,
        },
      );

      final model = SignupModel.fromJson(response);

      if (model.accessToken == null || model.accessToken!.isEmpty) {
        return {'success': false, 'message': 'Server did not return access token'};
      }

      if (model.user == null) {
        return {'success': false, 'message': 'Server did not return user data'};
      }

      _saveUserData(model);
      return {'success': true, 'data': model};
    } catch (e) {
      print('Google Sign-In error: $e');
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  void _saveUserData(SignupModel model) {
    StorageHelper().saveData('token', model.accessToken);
    StorageHelper().saveData('email', model.user!.email);
    StorageHelper().saveData('profile_email', model.user!.email);
    StorageHelper().saveData('userId', model.user!.id);
    if (model.user!.role != null && model.user!.role!.trim().isNotEmpty) {
      StorageHelper().saveData('role', model.user!.role!.trim());
    }
    if ((model.user!.fullName ?? model.user!.username) != null) {
      StorageHelper().saveData(
        'profile_name',
        (model.user!.fullName ?? model.user!.username)!.trim(),
      );
    }
    if (model.user!.profileImage != null &&
        model.user!.profileImage!.trim().isNotEmpty) {
      StorageHelper().saveData(
        'profile_image',
        model.user!.profileImage!.trim(),
      );
    }
    if (model.user!.location != null) {
      StorageHelper().saveData(
        'profile_location',
        model.user!.location!.trim(),
      );
    }
    if (model.user!.verificationStatus != null &&
        model.user!.verificationStatus!.trim().isNotEmpty) {
      StorageHelper().saveData(
        'verificationStatus',
        model.user!.verificationStatus!.trim(),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Firebase/Google sign out error: $e');
    }
  }
}
