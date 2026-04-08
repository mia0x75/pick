import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'ui/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'shared/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 获取屏幕实际尺寸
  final physicalSize = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
  final devicePixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  final screenWidth = physicalSize.width / devicePixelRatio;
  final screenHeight = physicalSize.height / devicePixelRatio;

  // 设置设计分辨率
  final designSize = AppConstants.getDesignSize(screenWidth, screenHeight);

  // 同步初始化 Hive（必须等待完成）
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(AppConstants.settingsBox),
    Hive.openBox(AppConstants.historyBox),
    Hive.openBox(AppConstants.cacheBox),
    Hive.openBox(AppConstants.credentialsBox),
    Hive.openBox(AppConstants.nodesBox),
    Hive.openBox(AppConstants.favoritesBox),
  ]);

  // 后台初始化 MediaKit
  Isolate.spawn(_initMediaKit, null);

  runApp(
    ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return ProviderScope(
          child: MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const SplashScreen(),
          ),
        );
      },
    ),
  );
}

void _initMediaKit(dynamic _) {
  try {
    MediaKit.ensureInitialized();
  } catch (e) {
    debugPrint('⚠️ MediaKit 初始化失败: $e');
  }
}
