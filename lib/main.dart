import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_demo/controller/auth_controller.dart';
import 'package:login_demo/core/theme/app_theme.dart';
import 'package:login_demo/firebase_options.dart';
import 'package:login_demo/view/screens/auth/login_screen.dart';
import 'package:login_demo/view/screens/home/home_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _minTimeDone = false;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _minTimeDone = true);
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLink(uri);
    });
    _linkSub = _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    final link = uri.toString();
    debugPrint('Incoming link: $link');
    if (FirebaseAuth.instance.isSignInWithEmailLink(link)) {
      ref.read(emailLinkControllerProvider.notifier).completeSignIn(link);
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (_, next) {
      if (next.value != null) {
        navigatorKey.currentState?.popUntil((r) => r.isFirst);
      }
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Login Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: !_minTimeDone
          ? const _SplashScreen()
          : authState.when(
              data: (user) =>
                  user != null ? const HomeScreen() : const LoginScreen(),
              loading: () => const _SplashScreen(),
              error: (e, __) {
                debugPrint('Auth stream error: $e');
                return const LoginScreen();
              },
            ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A12),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
    );
  }
}
