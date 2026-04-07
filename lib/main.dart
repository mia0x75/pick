import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/services/webdav_service.dart';
import 'core/services/smb_service.dart';
import 'core/services/bluetooth_service.dart';
import 'core/services/websocket_service.dart';
import 'core/sync/sync_manager.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'shared/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Hive.initFlutter();
  await _openHiveBoxes();

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '',
      );
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(const ProviderScope(child: PickPlayerApp())),
  );
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
  final _webdavService = WebDavService();
  final _smbService = SmbService();
  final _btService = BluetoothService();
  final _wsService = WebSocketService();
  final _syncManager = SyncManager();

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      await _webdavService.init();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
    }
    try {
      await _smbService.init();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
    }
    try {
      await _btService.init();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
    }
    try {
      await _wsService.startServer();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
    }
    try {
      await _syncManager.init();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
    }
  }

  @override
  void dispose() {
    _btService.dispose();
    _webdavService.dispose();
    _smbService.dispose();
    _wsService.dispose();
    _syncManager.dispose();
    super.dispose();
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
