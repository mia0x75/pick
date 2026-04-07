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
  bool _isAvailable = false;

  bool get isNear => _isNear;

  Stream<bool> get nearStream => _nearController.stream;
  final StreamController<bool> _nearController = StreamController<bool>.broadcast();

  Future<void> init() async {
    try {
      _isAvailable = await FlutterBluePlus.isSupported;
      if (!_isAvailable) return;

      _heartbeatTimer = Timer.periodic(
        AppConstants.bluetoothScanInterval,
        (_) => _scanForDevice(),
      );
    } catch (e) {
      // BLE not available on this device (common on Android TV)
      _isAvailable = false;
    }
  }

  Future<void> _scanForDevice() async {
    if (!_isAvailable) return;
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final rssi = result.rssi.toDouble();
          _processRssiSample(rssi);
        }
      });

      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      // BLE scan failed (permission denied or hardware unavailable)
    }
  }

  void _processRssiSample(double rssi) {
    _lastDeviceSeen = DateTime.now();

    if (rssi > AppConstants.rssiNearThreshold) {
      _nearSampleCount++;
    } else if (rssi < AppConstants.rssiFarThreshold) {
      _nearSampleCount = 0;
    }

    if (_nearSampleCount >= AppConstants.rssiSampleCount && !_isNear) {
      _isNear = true;
      _nearController.add(true);
    }

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
