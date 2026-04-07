import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter_bugly/flutter_bugly.dart';

import 'ui/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'shared/constants.dart';

void main() {
  // Bugly FIRST — wraps everything
  FlutterBugly.postCatchedException(() {
    runZonedGuarded(() async {
      // 1. Bugly init — absolute first
      await FlutterBugly.init(
        androidAppId: '75b96efd9c',
        debugMode: true,
      );

      // 2. Test message — verify Bugly is connected
      FlutterBugly.uploadException(
        type: 'AppStart',
        message: 'Pick Player v0.1.0 starting',
        detail: 'device: Android, abi: arm64-v8a',
      );

      // 3. Flutter binding
      WidgetsFlutterBinding.ensureInitialized();

      // 4. MediaKit
      try {
        MediaKit.ensureInitialized();
        FlutterBugly.uploadException(
          type: 'MediaKit',
          message: 'MediaKit initialized OK',
          detail: '',
        );
      } catch (e, st) {
        FlutterBugly.uploadException(
          type: 'MediaKitInit',
          message: '$e',
          detail: '$st',
        );
      }

      // 5. Orientation
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } catch (e, st) {
        FlutterBugly.uploadException(
          type: 'SystemChrome',
          message: '$e',
          detail: '$st',
        );
      }

      // 6. Hive
      try {
        await Hive.initFlutter();
        await _openHiveBoxes();
        FlutterBugly.uploadException(
          type: 'Hive',
          message: 'Hive initialized OK',
          detail: '',
        );
      } catch (e, st) {
        FlutterBugly.uploadException(
          type: 'HiveInit',
          message: '$e',
          detail: '$st',
        );
      }

      // 7. Run app
      FlutterBugly.uploadException(
        type: 'RunApp',
        message: 'Calling runApp',
        detail: '',
      );
      runApp(const ProviderScope(child: PickPlayerApp()));
    }, (error, stackTrace) {
      // CATCH ALL
      FlutterBugly.uploadException(
        type: 'UncaughtError',
        message: '$error',
        detail: '$stackTrace',
      );
      debugPrint('UNCAUGHT: $error\n$stackTrace');
    });
  });
}

Future<void> _openHiveBoxes() async {
  await Future.wait([
    Hive.openBox(AppConstants.settingsBox),
    Hive.openBox(AppConstants.historyBox),
    Hive.openBox(AppConstants.cacheBox),
    Hive.openBox(AppConstants.credentialsBox),
    Hive.openBox(AppConstants.nodesBox),
    Hive.openBox(AppConstants.favoritesBox),
  ]);
}

class PickPlayerApp extends ConsumerStatefulWidget {
  const PickPlayerApp({super.key});

  @override
  ConsumerState<PickPlayerApp> createState() => _PickPlayerAppState();
}

class _PickPlayerAppState extends ConsumerState<PickPlayerApp> {
  @override
  void initState() {
    super.initState();
    // No service initialization — test if app can start at all
  }

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
