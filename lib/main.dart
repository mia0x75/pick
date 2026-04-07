import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'core/services/webdav_service.dart';
import 'core/services/smb_service.dart';
import 'core/services/bluetooth_service.dart';
import 'core/services/websocket_service.dart';
import 'core/sync/sync_manager.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'shared/constants.dart';

/// Local crash logger — writes crash reports to a file, readable on next launch.
class _CrashLogger {
  static const _crashFile = '/data/data/com.mxu.pick/crash.log';

  static void init() {
    // Catch Flutter errors
    FlutterError.onError = (details) {
      _writeCrash('FlutterError', details.exceptionAsString(), details.stack);
    };

    // Catch all other uncaught errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _writeCrash('PlatformDispatcher', error.toString(), stack);
      return true;
    };

    // Catch native crashes via logcat
    _writeCrash('AppStart', 'App launched at ${DateTime.now().toIso8601String()}', null);
  }

  static void _writeCrash(String source, String error, StackTrace? stack) {
    try {
      final file = File(_crashFile);
      final log = '''
========================================
CRASH REPORT — ${DateTime.now().toIso8601String()}
========================================
Source: $source
Error:  $error
Stack:
${stack?.toString() ?? '(no stack trace)'}
========================================

''';
      file.writeAsStringSync(log, mode: FileMode.append);
    } catch (e) {
      // If we can't write the crash log, print it
      debugPrint('Failed to write crash log: $e');
      debugPrint('$source: $error');
      debugPrint('$stack');
    }
  }

  static String? readCrashLog() {
    try {
      final file = File(_crashFile);
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
    } catch (e) {
      debugPrint('Failed to read crash log: $e');
    }
    return null;
  }

  static void clearCrashLog() {
    try {
      final file = File(_crashFile);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      // Ignore
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize crash logger first
  _CrashLogger.init();

  try {
    MediaKit.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    await Hive.initFlutter();
    await _openHiveBoxes();
  } catch (e, st) {
    _CrashLogger._writeCrash('Init', '$e', st);
    rethrow;
  }

  runApp(const ProviderScope(child: PickPlayerApp()));
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
      debugPrint('WebDAV init error: $e\n$st');
    }
    try {
      await _smbService.init();
    } catch (e, st) {
      debugPrint('SMB init error: $e\n$st');
    }
    try {
      await _btService.init();
    } catch (e, st) {
      debugPrint('Bluetooth init error: $e\n$st');
    }
    try {
      await _wsService.startServer();
    } catch (e, st) {
      debugPrint('WebSocket init error: $e\n$st');
    }
    try {
      await _syncManager.init();
    } catch (e, st) {
      debugPrint('Sync init error: $e\n$st');
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
