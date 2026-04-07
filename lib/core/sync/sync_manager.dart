import 'dart:convert';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/constants.dart';
import '../models/media_progress.dart';
import '../services/webdav_service.dart';

class SyncManager {
  final WebDavService _webdavService = WebDavService();
  Timer? _pollTimer;
  // ignore: unused_field
  String _deviceId = '';

  Future<void> init() async {
    // Load device ID
    final box = Hive.box(AppConstants.settingsBox);
    _deviceId = box.get('device_id', defaultValue: 'unknown-tv');

    // Start periodic sync
    _pollTimer = Timer.periodic(
      AppConstants.syncPollInterval,
      (_) => _syncCycle(),
    );
  }

  Future<void> saveProgress(MediaProgress progress) async {
    // Save locally
    final box = Hive.box(AppConstants.historyBox);
    await box.put(progress.mediaId, jsonEncode(progress.toJson()));

    // Upload to cloud
    await _uploadSyncFile();
  }

  Future<MediaProgress?> getProgress(String mediaId) async {
    // Check local first
    final box = Hive.box(AppConstants.historyBox);
    final localData = box.get(mediaId);
    if (localData != null) {
      return MediaProgress.fromJson(jsonDecode(localData) as Map<String, dynamic>);
    }

    // Check cloud
    final remoteProgress = await _downloadSyncFile();
    return remoteProgress?[mediaId];
  }

  Future<List<MediaProgress>> getAllProgress() async {
    final localBox = Hive.box(AppConstants.historyBox);
    final localList = <MediaProgress>[];

    for (final key in localBox.keys) {
      final data = localBox.get(key);
      if (data != null) {
        localList.add(MediaProgress.fromJson(jsonDecode(data) as Map<String, dynamic>));
      }
    }

    // Merge with remote
    final remoteProgress = await _downloadSyncFile();
    if (remoteProgress != null) {
      for (final progress in remoteProgress.values) {
        final existingIndex = localList.indexWhere((p) => p.mediaId == progress.mediaId);
        if (existingIndex >= 0) {
          // LWW: keep the one with later updatedAt
          if (progress.updatedAt.isAfter(localList[existingIndex].updatedAt)) {
            localList[existingIndex] = progress;
          }
        } else {
          localList.add(progress);
        }
      }
    }

    return localList;
  }

  Future<void> _syncCycle() async {
    try {
      await _uploadSyncFile();
    } catch (e) {
      // Silently fail, next cycle will retry
    }
  }

  Future<void> _uploadSyncFile() async {
    if (!_webdavService.isConnected) return;

    await getAllProgress();
    // TODO: write syncData to WebDAV
  }

  Future<Map<String, MediaProgress>?> _downloadSyncFile() async {
    if (!_webdavService.isConnected) return null;

    try {
      // Read from WebDAV
      // Placeholder: actual implementation reads JSON from WebDAV
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _pollTimer?.cancel();
  }
}
