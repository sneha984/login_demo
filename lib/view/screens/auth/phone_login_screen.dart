import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:login_demo/controller/auth_controller.dart';
import 'package:login_demo/core/theme/app_theme.dart';
import 'package:pinput/pinput.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  String _fullPhoneNumber = '';
  final _otpCtrl = TextEditingController();
  final _phoneFocusNode = FocusNode();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _phoneFocusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_fullPhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _phoneFocusNode.unfocus();
    await ref
        .read(phoneAuthControllerProvider.notifier)
        .sendOtp(_fullPhoneNumber);
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await ref
        .read(phoneAuthControllerProvider.notifier)
        .verifyOtp(_otpCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneAuthControllerProvider);
    final ctrl = ref.read(phoneAuthControllerProvider.notifier);

    ref.listen(phoneAuthControllerProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ctrl.clearError();
      }
      if (prev?.step == PhoneAuthStep.verifyOtp &&
          next.step == PhoneAuthStep.inputPhone) {
        _otpCtrl.clear();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.onBackground,
            size: 20,
          ),
          onPressed: () {
            if (state.step == PhoneAuthStep.verifyOtp) {
              ctrl.goBack();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: state.step == PhoneAuthStep.inputPhone
                    ? _PhoneInputSection(
                        key: const ValueKey('phone'),
                        fullPhoneNumber: _fullPhoneNumber,
                        onPhoneChanged: (p) =>
                            setState(() => _fullPhoneNumber = p),
                        focusNode: _phoneFocusNode,
                        isLoading: state.isLoading,
                        onSend: _sendOtp,
                      )
                    : _OtpSection(
                        key: const ValueKey('otp'),
                        otpCtrl: _otpCtrl,
                        isLoading: state.isLoading,
                        onVerify: _verifyOtp,
                        onResend: () {
                          _otpCtrl.clear();
                          ctrl.goBack();
                          Future.delayed(
                            const Duration(milliseconds: 300),
                            () => _sendOtp(),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneInputSection extends StatelessWidget {
  final String fullPhoneNumber;
  final void Function(String) onPhoneChanged;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  const _PhoneInputSection({
    super.key,
    required this.fullPhoneNumber,
    required this.onPhoneChanged,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'We\'ll send a 6-digit OTP to verify your number',
          style: TextStyle(fontSize: 14, color: AppTheme.onSurface),
        ),
        const SizedBox(height: 36),

        IntlPhoneField(
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '98765 43210',
            hintStyle: TextStyle(color: AppTheme.onSurface.withOpacity(0.5)),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            counterText: '',
          ),
          style: const TextStyle(color: AppTheme.onBackground),
          dropdownTextStyle: const TextStyle(color: AppTheme.onBackground),
          initialCountryCode: 'IN',
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (phone) => onPhoneChanged(phone.completeNumber),
        ),
        const SizedBox(height: 32),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : ElevatedButton(
                  onPressed: onSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Send OTP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
        ),
      ],
    );
  }
}

class _OtpSection extends StatelessWidget {
  final TextEditingController otpCtrl;
  final bool isLoading;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const _OtpSection({
    super.key,
    required this.otpCtrl,
    required this.isLoading,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: AppTheme.onBackground,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Verify OTP',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter the 6-digit code we sent to your phone',
          style: TextStyle(fontSize: 14, color: AppTheme.onSurface),
        ),
        const SizedBox(height: 40),

        Center(
          child: Pinput(
            controller: otpCtrl,
            length: 6,
            autofocus: true,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: AppTheme.primary, width: 1.5),
              ),
            ),
            submittedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                color: AppTheme.primary.withOpacity(0.15),
                border: Border.all(color: AppTheme.primary),
              ),
            ),
            onCompleted: (_) => onVerify(),
          ),
        ),

        const SizedBox(height: 40),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : ElevatedButton(
                  onPressed: onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Verify OTP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
        ),

        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: onResend,
            child: const Text.rich(
              TextSpan(
                text: "Didn't receive the code? ",
                style: TextStyle(color: AppTheme.onSurface, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Resend',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
