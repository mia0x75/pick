import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'ui/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'shared/constants.dart';

@pragma('vm:entry-point')
void prewarm() {
  // 轻量预热，仅让 engine 与插件注册完成，不调用 runApp
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  const screenWidth = 1920.0;
  const screenHeight = 1080.0;
  final designSize = AppConstants.getDesignSize(screenWidth, screenHeight);

  if (kDebugMode) debugPrint('🚀 main: 启动 runApp');
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

  _startBackgroundInit();
}

void _startBackgroundInit() {
  if (kDebugMode) debugPrint('🔄 background: 开始初始化');
  Isolate.spawn(_initMediaKit, null);

  Future.microtask(() async {
    try {
      if (kDebugMode) debugPrint('🔄 background: Hive.initFlutter()');
      await Hive.initFlutter();
      
      if (kDebugMode) debugPrint('🔄 background: 等待 600ms');
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (kDebugMode) debugPrint('🔄 background: 打开 Hive boxes');
      await Future.wait([
        Hive.openBox(AppConstants.settingsBox),
        Hive.openBox(AppConstants.historyBox),
        Hive.openBox(AppConstants.cacheBox),
        Hive.openBox(AppConstants.credentialsBox),
        Hive.openBox(AppConstants.nodesBox),
        Hive.openBox(AppConstants.favoritesBox),
      ]);
      if (kDebugMode) debugPrint('✅ background: Hive boxes opened');
    } catch (e, st) {
      debugPrint('⚠️ background: Hive 初始化失败: $e\n$st');
    }
  });
}

void _initMediaKit(dynamic _) {
  try {
    if (kDebugMode) debugPrint('🔄 background: MediaKit 初始化');
    MediaKit.ensureInitialized();
    if (kDebugMode) debugPrint('✅ background: MediaKit 初始化完成');
  } catch (e) {
    debugPrint('⚠️ background: MediaKit 初始化失败: $e');
  }
}
