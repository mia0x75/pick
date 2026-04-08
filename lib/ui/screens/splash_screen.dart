import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'home_screen.dart';
import '../widgets/glow_loading_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    final minimumSplashDuration = Future.delayed(const Duration(milliseconds: 1500));

    bool hasRelayAction = false;
    final initializationTasks = _performInitTasks().then((relay) {
      hasRelayAction = relay;
    });

    await Future.wait([minimumSplashDuration, initializationTasks]);

    if (!mounted) return;

    if (hasRelayAction) {
      // TODO: 发现接力推送，直接进入播放器全屏播放
    } else {
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

  Future<bool> _performInitTasks() async {
    try {
      MediaKit.ensureInitialized();

      bool relayDetected = false;

      await Future.wait([
        _startWebSocketServer(),
        _checkDeviceRelay().then((hasRelay) => relayDetected = hasRelay),
      ]).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⚠️ 网络初始化超时，优雅降级');
          return [];
        },
      );

      return relayDetected;
    } catch (e) {
      debugPrint('💥 初始化异常: $e');
      return false;
    }
  }

  Future<void> _startWebSocketServer() async {
    // TODO: 启动 WebSocket 服务
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<bool> _checkDeviceRelay() async {
    // TODO: 检查 relay_action.json
    await Future.delayed(const Duration(milliseconds: 300));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash_background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.9 + (0.1 * value),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 160.w,
                    height: 160.w,
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    'Pick 片刻',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 56.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '极简 · 安全 · 互通',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24.sp,
                      letterSpacing: 12,
                    ),
                  ),
                  SizedBox(height: 80.h),
                  const GlowLoadingAnimation(size: 56),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
