import 'package:firebase_auth/firebase_auth.dart';

class AuthModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final String provider;

  const AuthModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    required this.provider,
  });

  factory AuthModel.fromFirebaseUser(User user) {
    final providerId = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'unknown';
    return AuthModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      phoneNumber: user.phoneNumber,
      provider: providerId,
    );
  }

  String get displayProvider {
    switch (provider) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'password':
        return 'Email';
      case 'phone':
        return 'Phone';
      default:
        return 'Unknown';
    }
  }
}
