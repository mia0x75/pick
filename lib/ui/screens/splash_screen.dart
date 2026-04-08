import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 80),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pick 片刻',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                '极简 · 安全 · 互通',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18.sp,
                  letterSpacing: 8,
                ),
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: 24.w,
                height: 24.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
