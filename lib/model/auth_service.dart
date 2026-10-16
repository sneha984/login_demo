import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:login_demo/model/auth_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Email Link (Passwordless) ─────────────────────────────────────────────

  /// Sends a sign-in link to [email]. The link will open the app via deep link.
  Future<void> sendEmailSignInLink(String email) async {
    final actionCodeSettings = ActionCodeSettings(
      // Replace with your actual Firebase project URL or custom domain
      url: 'https://logindemo-fb6d0.firebaseapp.com/emailSignIn',
      handleCodeInApp: true,
      androidPackageName: 'com.example.login_demo',
      androidInstallApp: true,
      androidMinimumVersion: '23',
      iOSBundleId: 'com.example.loginDemo',
    );
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  /// Completes sign-in using the [emailLink] received via deep link.
  Future<AuthModel> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final userCredential = await _auth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );
    return AuthModel.fromFirebaseUser(userCredential.user!);
  }

  /// Returns true if [link] is a valid sign-in email link.
  bool isSignInLink(String link) => _auth.isSignInWithEmailLink(link);

  // ─── Google ────────────────────────────────────────────────────────────────

  Future<AuthModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return AuthModel.fromFirebaseUser(userCredential.user!);
  }

  // ─── Apple ─────────────────────────────────────────────────────────────────

  Future<AuthModel> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);
    return AuthModel.fromFirebaseUser(userCredential.user!);
  }

  // ─── Phone Number ──────────────────────────────────────────────────────────

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<AuthModel> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return AuthModel.fromFirebaseUser(userCredential.user!);
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // ─── Current User ──────────────────────────────────────────────────────────

  AuthModel? get currentUser {
    final user = _auth.currentUser;
    return user != null ? AuthModel.fromFirebaseUser(user) : null;
  }
}
