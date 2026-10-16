import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_demo/controller/auth_controller.dart';
import 'package:login_demo/core/theme/app_theme.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(emailLinkControllerProvider.notifier)
        .sendLink(_emailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailLinkControllerProvider);
    final ctrl = ref.read(emailLinkControllerProvider.notifier);

    ref.listen(emailLinkControllerProvider, (_, next) {
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        ctrl.clearError();
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
            if (state.step == EmailLinkStep.linkSent) {
              ctrl.goBack();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: state.step == EmailLinkStep.inputEmail
                  ? _EmailInputSection(
                      key: const ValueKey('input'),
                      formKey: _formKey,
                      controller: _emailCtrl,
                      isLoading: state.isLoading,
                      onSend: _sendLink,
                    )
                  : _LinkSentSection(
                      key: const ValueKey('sent'),
                      email: state.email ?? '',
                      isLoading: state.isLoading,
                      onResend: () {
                        ctrl.goBack();
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          () => _sendLink(),
                        );
                      },
                      onChangeEmail: () => ctrl.goBack(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailInputSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _EmailInputSection({
    super.key,
    required this.formKey,
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Sign in with Email',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppTheme.onBackground,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your email and we\'ll send a\nsecure sign-in link to your inbox.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.onSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),

          TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSend(),
            style: const TextStyle(color: AppTheme.onBackground),
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'you@example.com',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppTheme.onSurface,
                size: 20,
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Send button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : ElevatedButton.icon(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Send Sign-In Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              'No password needed — just click the link\nwe send to your inbox.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkSentSection extends StatefulWidget {
  final String email;
  final bool isLoading;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;

  const _LinkSentSection({
    super.key,
    required this.email,
    required this.isLoading,
    required this.onResend,
    required this.onChangeEmail,
  });

  @override
  State<_LinkSentSection> createState() => _LinkSentSectionState();
}

class _LinkSentSectionState extends State<_LinkSentSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        ScaleTransition(
          scale: _pulse,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.2),
                  AppTheme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 46,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 32),

        const Text(
          'Check your inbox!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'We sent a sign-in link to',
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.onSurface.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // Email highlight chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Text(
            widget.email,
            style: const TextStyle(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            children: [
              _StepRow(number: '1', text: 'Open your email app'),
              const SizedBox(height: 14),
              _StepRow(
                number: '2',
                text: 'Find the email from Firebase / Login Demo',
              ),
              const SizedBox(height: 14),
              _StepRow(
                number: '3',
                text: 'Tap "Sign in to Login Demo" — you\'re in!',
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Resend button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.isLoading
              ? const CircularProgressIndicator(color: AppTheme.primary)
              : OutlinedButton.icon(
                  onPressed: widget.onResend,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Resend Link'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: widget.onChangeEmail,
          child: const Text(
            'Use a different email',
            style: TextStyle(color: AppTheme.onSurface, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.onBackground,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
