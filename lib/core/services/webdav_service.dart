import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../shared/constants.dart';

class WebDavService {
  Client? _client;
  final Map<String, dynamic> _dirCache = {};
  final Map<String, DateTime> _cacheExpiry = {};

  bool get isConnected => _client != null;

  Future<void> init() async {
    // Load cached credentials
    final box = Hive.box(AppConstants.credentialsBox);
    final storedUrl = box.get('webdav_url');
    final storedUser = box.get('webdav_user');
    final storedPass = box.get('webdav_pass');

    if (storedUrl != null) {
      await connect(
        baseUrl: storedUrl,
        username: storedUser,
        password: storedPass,
      );
    }
  }

  Future<void> connect({
    required String baseUrl,
    String? username,
    String? password,
  }) async {
    _client = newClient(
      baseUrl,
      user: username,
      password: password,
    );

    _client!.setHeaders({
      'accept-charset': 'utf-8',
    });

    _client!.setConnectTimeout(AppConstants.networkTimeout.inMilliseconds);
    _client!.setSendTimeout(AppConstants.networkTimeout.inMilliseconds);
    _client!.setReceiveTimeout(AppConstants.networkTimeout.inMilliseconds);

    // Test connection
    await _client!.ping();
  }

  Future<List<Map<String, dynamic>>> listDir(String path) async {
    final cacheKey = path;
    final now = DateTime.now();

    // Check cache
    if (_dirCache.containsKey(cacheKey) &&
        _cacheExpiry.containsKey(cacheKey) &&
        now.isBefore(_cacheExpiry[cacheKey]!)) {
      return List<Map<String, dynamic>>.from(_dirCache[cacheKey]);
    }

    // Retry with exponential backoff
    List<Map<String, dynamic>> result;
    var retryCount = 0;
    while (true) {
      try {
        final items = await _client!.readDir(path);
        result = items.map((item) {
          return {
            'name': item.name,
            'path': item.path,
            'isDir': item.isDir,
            'size': item.size,
            'lastModified': item.lastModified?.toIso8601String(),
          };
        }).toList();
        break;
      } catch (e) {
        retryCount++;
        if (retryCount >= AppConstants.maxRetryCount) {
          throw StorageException(
            code: 'WEBDAV_LIST_FAILED',
            message: 'Failed to list directory: $e',
            recoverable: false,
          );
        }
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }

    // Cache result
    _dirCache[cacheKey] = result;
    _cacheExpiry[cacheKey] = now.add(AppConstants.directoryCacheTtl);

    return result;
  }

  Stream<List<int>> readFileStream(String path) async* {
    try {
      final stream = await _client!.read(path);
      await for (final chunk in stream) {
        if (chunk is List<int>) {
          yield chunk;
        }
      }
    } catch (e) {
      throw StorageException(
        code: 'WEBDAV_READ_FAILED',
        message: 'Failed to read file: $e',
        recoverable: true,
      );
    }
  }

  void dispose() {
    _client = null;
    _dirCache.clear();
    _cacheExpiry.clear();
  }
}

class StorageException implements Exception {
  final String code;
  final String message;
  final bool recoverable;

  StorageException({
    required this.code,
    required this.message,
    this.recoverable = true,
  });

  @override
  String toString() => 'StorageException($code): $message';
}
