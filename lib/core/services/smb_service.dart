import 'webdav_service.dart';

class SmbService {
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    // Initialize SMB service
    // Note: libsmbclient requires FFI binding; placeholder for cloud build
    _initialized = true;
  }

  Future<List<Map<String, dynamic>>> listDir(String smbUrl) async {
    if (!_initialized) {
      throw StorageException(
        code: 'SMB_NOT_INITIALIZED',
        message: 'SMB service not initialized',
        recoverable: false,
      );
    }

    // Parse SMB URL: smb://host/share/path
    final uri = Uri.parse(smbUrl);
    if (uri.scheme != 'smb') {
      throw StorageException(
        code: 'SMB_INVALID_URL',
        message: 'Invalid SMB URL scheme',
        recoverable: false,
      );
    }

    // Placeholder: actual implementation uses libsmbclient FFI
    return [];
  }

  Stream<List<int>> readFileStream(String smbUrl) async* {
    if (!_initialized) {
      throw StorageException(
        code: 'SMB_NOT_INITIALIZED',
        message: 'SMB service not initialized',
        recoverable: false,
      );
    }

    // Placeholder: actual implementation uses libsmbclient FFI
    yield* const Stream.empty();
  }

  void dispose() {
    _initialized = false;
  }
}
