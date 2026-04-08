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

  _startBackgroundInit();

  runApp(const ProviderScope(child: PickPlayerApp()));
}

void _startBackgroundInit() {
  // 等待 Hive 初始化完成后再打开盒子
  Hive.initFlutter().then((_) {
    unawaited(Future.wait([
      Hive.openBox(AppConstants.settingsBox),
      Hive.openBox(AppConstants.historyBox),
      Hive.openBox(AppConstants.cacheBox),
      Hive.openBox(AppConstants.credentialsBox),
      Hive.openBox(AppConstants.nodesBox),
      Hive.openBox(AppConstants.favoritesBox),
    ],),);
  });

  // MediaKit 在后台 Isolate 初始化
  Isolate.spawn((_) => MediaKit.ensureInitialized(), null);
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
