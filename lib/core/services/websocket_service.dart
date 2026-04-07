import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../shared/constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> startServer() async {
    // Note: web_socket_channel doesn't support server mode.
    // For TV-side WebSocket server, use dart:io HttpServer + WebSocketTransformer.
    // This is a placeholder for the sync relay pattern.
  }

  Future<void> connect(String uri) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(uri));
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as Map<String, dynamic>;
            _messageController.add(message);
          } catch (e) {
            // Ignore non-JSON messages
          }
        },
        onError: (_) => _scheduleReconnect(uri),
        onDone: () => _scheduleReconnect(uri),
      );
    } catch (e) {
      _scheduleReconnect(uri);
    }
  }

  void _scheduleReconnect(String uri) {
    _isConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(
      AppConstants.wsReconnectInterval,
      (_) {
        if (!_isConnected) {
          connect(uri);
        } else {
          _reconnectTimer?.cancel();
        }
      },
    );
  }

  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
