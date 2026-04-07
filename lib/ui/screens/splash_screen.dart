import 'package:flutter/material.dart';

import '../widgets/glow_loading_animation.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/splash_background.png',
            fit: BoxFit.cover,
          ),
          // Dark overlay for readability
          Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Image.asset(
                  'assets/images/app_icon.jpg',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                // App name
                const Text(
                  'Pick 片刻',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline
                const Text(
                  '极简  安全  互通',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 48),
                // Glow loading animation
                const GlowLoadingAnimation(size: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
