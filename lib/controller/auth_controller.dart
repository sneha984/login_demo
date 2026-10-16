import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_demo/model/auth_model.dart';
import 'package:login_demo/model/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = Provider<AuthModel?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return user != null ? AuthModel.fromFirebaseUser(user) : null;
});

enum EmailLinkStep { inputEmail, linkSent }

class EmailLinkState {
  final EmailLinkStep step;
  final bool isLoading;
  final String? error;
  final String? email;

  const EmailLinkState({
    this.step = EmailLinkStep.inputEmail,
    this.isLoading = false,
    this.error,
    this.email,
  });

  EmailLinkState copyWith({
    EmailLinkStep? step,
    bool? isLoading,
    String? error,
    String? email,
  }) {
    return EmailLinkState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      email: email ?? this.email,
    );
  }
}

class EmailLinkController extends StateNotifier<EmailLinkState> {
  final AuthService _service;
  EmailLinkController(this._service) : super(const EmailLinkState());

  Future<void> sendLink(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.sendEmailSignInLink(email);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emailForSignIn', email);
      state = EmailLinkState(step: EmailLinkStep.linkSent, email: email);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e.code));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send link. Please try again.',
      );
    }
  }

  Future<void> completeSignIn(String emailLink) async {
    final prefs = await SharedPreferences.getInstance();
    final email = state.email ?? prefs.getString('emailForSignIn');
    if (email == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Please enter your email again and request a new link.',
      );
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.signInWithEmailLink(email: email, emailLink: emailLink);
      await prefs.remove('emailForSignIn');
      state = const EmailLinkState(); // reset
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e.code));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign-in failed. Please try again.',
      );
    }
  }

  void goBack() => state = const EmailLinkState();
  void clearError() => state = state.copyWith(error: null);

  String _mapError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-action-code':
        return 'The sign-in link is invalid or expired.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

final emailLinkControllerProvider =
    StateNotifierProvider<EmailLinkController, EmailLinkState>((ref) {
      return EmailLinkController(ref.read(authServiceProvider));
    });

class SocialAuthState {
  final bool isGoogleLoading;
  final bool isAppleLoading;
  final String? error;

  const SocialAuthState({
    this.isGoogleLoading = false,
    this.isAppleLoading = false,
    this.error,
  });

  SocialAuthState copyWith({
    bool? isGoogleLoading,
    bool? isAppleLoading,
    String? error,
  }) {
    return SocialAuthState(
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      isAppleLoading: isAppleLoading ?? this.isAppleLoading,
      error: error,
    );
  }
}

class SocialAuthController extends StateNotifier<SocialAuthState> {
  final AuthService _service;
  SocialAuthController(this._service) : super(const SocialAuthState());

  Future<void> signInWithGoogle() async {
    state = const SocialAuthState(isGoogleLoading: true);
    try {
      await _service.signInWithGoogle();
      state = const SocialAuthState();
    } on FirebaseAuthException catch (e) {
      state = SocialAuthState(error: e.message ?? 'Google sign-in failed.');
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        state = const SocialAuthState();
      } else {
        state = SocialAuthState(error: 'Google sign-in failed. Try again.');
      }
    }
  }

  Future<void> signInWithApple() async {
    state = const SocialAuthState(isAppleLoading: true);
    try {
      await _service.signInWithApple();
      state = const SocialAuthState();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        state = const SocialAuthState();
      } else {
        state = SocialAuthState(error: 'Apple sign-in failed. Try again.');
      }
    } catch (e) {
      state = SocialAuthState(error: 'Apple sign-in failed. Try again.');
    }
  }

  void clearError() => state = const SocialAuthState();
}

final socialAuthControllerProvider =
    StateNotifierProvider<SocialAuthController, SocialAuthState>((ref) {
      return SocialAuthController(ref.read(authServiceProvider));
    });

enum PhoneAuthStep { inputPhone, verifyOtp }

class PhoneAuthState {
  final PhoneAuthStep step;
  final bool isLoading;
  final String? error;
  final String? verificationId;
  final bool success;

  const PhoneAuthState({
    this.step = PhoneAuthStep.inputPhone,
    this.isLoading = false,
    this.error,
    this.verificationId,
    this.success = false,
  });

  PhoneAuthState copyWith({
    PhoneAuthStep? step,
    bool? isLoading,
    String? error,
    String? verificationId,
    bool? success,
  }) {
    return PhoneAuthState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      success: success ?? this.success,
    );
  }
}

class PhoneAuthController extends StateNotifier<PhoneAuthState> {
  final AuthService _service;
  PhoneAuthController(this._service) : super(const PhoneAuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    await _service.sendOtp(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          state = state.copyWith(isLoading: false, success: true);
        } catch (_) {
          state = state.copyWith(
            isLoading: false,
            error: 'Auto-verification failed.',
          );
        }
      },
      verificationFailed: (e) {
        state = state.copyWith(
          isLoading: false,
          error: e.message ?? 'Verification failed.',
        );
      },
      codeSent: (verificationId, _) {
        state = state.copyWith(
          isLoading: false,
          step: PhoneAuthStep.verifyOtp,
          verificationId: verificationId,
        );
      },
      codeAutoRetrievalTimeout: (_) {
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<void> verifyOtp(String otp) async {
    if (state.verificationId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.verifyOtp(verificationId: state.verificationId!, otp: otp);
      state = state.copyWith(isLoading: false, success: true);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.code == 'invalid-verification-code'
            ? 'Incorrect OTP. Please try again.'
            : e.message ?? 'Verification failed.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Verification failed.');
    }
  }

  void goBack() {
    state = const PhoneAuthState();
  }

  void clearError() => state = state.copyWith(error: null);
}

final phoneAuthControllerProvider =
    StateNotifierProvider<PhoneAuthController, PhoneAuthState>((ref) {
      return PhoneAuthController(ref.read(authServiceProvider));
    });

final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final service = ref.read(authServiceProvider);
    await service.signOut();
  };
});
