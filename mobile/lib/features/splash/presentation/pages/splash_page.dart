import 'package:flutter/material.dart';

/// Shown while the auth session is being restored, right after the native
/// launch screen hands off to Flutter — same image/background so the
/// transition into the app is seamless instead of flashing a blank frame.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Image(
            image: AssetImage('assets/images/splash-screen.png'),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
