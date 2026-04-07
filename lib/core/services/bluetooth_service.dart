import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../shared/constants.dart';

class BluetoothService {
  StreamSubscription? _scanSubscription;
  Timer? _scanTimer;
  Timer? _heartbeatTimer;
  bool _isNear = false;
  int _nearSampleCount = 0;
  DateTime? _lastDeviceSeen;

  bool get isNear => _isNear;

  Stream<bool> get nearStream => _nearController.stream;
  final StreamController<bool> _nearController = StreamController<bool>.broadcast();

  Future<void> init() async {
    // Start periodic BLE scanning
    _heartbeatTimer = Timer.periodic(
      AppConstants.bluetoothScanInterval,
      (_) => _scanForDevice(),
    );
  }

  Future<void> _scanForDevice() async {
    try {
      // Load target device ID from settings
      // Placeholder: actual device ID stored in Hive

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final rssi = result.rssi.toDouble();
          _processRssiSample(rssi);
        }
      });

      // Stop scanning after timeout
      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      // BLE not available or permission denied
    }
  }

  void _processRssiSample(double rssi) {
    _lastDeviceSeen = DateTime.now();

    if (rssi > AppConstants.rssiNearThreshold) {
      _nearSampleCount++;
    } else if (rssi < AppConstants.rssiFarThreshold) {
      _nearSampleCount = 0;
    }

    // Check if we have enough consecutive near samples
    if (_nearSampleCount >= AppConstants.rssiSampleCount && !_isNear) {
      _isNear = true;
      _nearController.add(true);
    }

    // Check if device disappeared
    if (_lastDeviceSeen != null) {
      final elapsed = DateTime.now().difference(_lastDeviceSeen!);
      if (elapsed > AppConstants.bluetoothDisappearTimeout && _isNear) {
        _isNear = false;
        _nearSampleCount = 0;
        _nearController.add(false);
      }
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _scanTimer?.cancel();
    _heartbeatTimer?.cancel();
    _nearController.close();
  }
}
