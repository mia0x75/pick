import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'ui/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'shared/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 后台启动初始化，不阻塞 UI
  Future.microtask(() async {
    await Hive.initFlutter();
    // 延迟打开盒子，不阻塞 Splash
    Future.delayed(const Duration(milliseconds: 800), () {
      Future.wait([
        Hive.openBox(AppConstants.settingsBox),
        Hive.openBox(AppConstants.historyBox),
        Hive.openBox(AppConstants.cacheBox),
        Hive.openBox(AppConstants.credentialsBox),
        Hive.openBox(AppConstants.nodesBox),
        Hive.openBox(AppConstants.favoritesBox),
      ]);
    });
  });

  runApp(const ProviderScope(child: PickPlayerApp()));
}

class PickPlayerApp extends ConsumerStatefulWidget {
  const PickPlayerApp({super.key});

  @override
  ConsumerState<PickPlayerApp> createState() => _PickPlayerAppState();
}

class _PickPlayerAppState extends ConsumerState<PickPlayerApp> {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
