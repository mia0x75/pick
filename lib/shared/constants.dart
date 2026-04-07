import 'package:flutter/services.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Pick 片刻';
  static const String appVersion = '0.1.0';

  // TV Layout
  static const double tvEdgePadding = 96.0;
  static const double tvTopPadding = 54.0;
  static const double rowSpacing = 40.0;
  static const double cardBorderRadius = 12.0;
  static const double focusScaleFactor = 1.08;

  // Row 1 Accordion
  static const double row1CollapsedWidth = 100.0;
  static const double row1ExpandedWidth = 533.0;
  static const double row1Height = 300.0;
  static const Duration row1AnimationDuration = Duration(milliseconds: 300);

  // Row 2 & 3
  static const double row23CardWidth = 200.0;
  static const double row23CardHeight = 200.0;

  // Stealth
  static const int secretCodeLength = 5;
  static const Duration secretCodeTimeout = Duration(seconds: 2);
  static const List<LogicalKeyboardKey> defaultSecretCode = [
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.enter,
  ];
  static const Duration settingsIconLongPressDuration = Duration(seconds: 3);

  // Bluetooth
  static const double rssiNearThreshold = -60.0;
  static const double rssiFarThreshold = -75.0;
  static const int rssiSampleCount = 3;
  static const Duration bluetoothScanInterval = Duration(seconds: 5);
  static const Duration bluetoothDisappearTimeout = Duration(seconds: 15);

  // WebSocket
  static const int wsPort = 8765;
  static const Duration wsReconnectInterval = Duration(seconds: 5);

  // Sync
  static const String syncFileName = 'pick_sync.json';
  static const String relayFileName = 'pick_relay.json';
  static const Duration syncPollInterval = Duration(seconds: 30);

  // Cache
  static const Duration directoryCacheTtl = Duration(seconds: 60);
  static const int maxRetryCount = 3;
  static const Duration networkTimeout = Duration(seconds: 15);

  // Video preview
  static const Duration videoPreviewDelay = Duration(seconds: 1);

  // Hive boxes
  static const String settingsBox = 'settings';
  static const String historyBox = 'history';
  static const String cacheBox = 'cache';
  static const String credentialsBox = 'credentials';
  static const String nodesBox = 'nodes';
  static const String favoritesBox = 'favorites';
}
