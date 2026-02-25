import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/tron_agent_log_model.dart';

class TronWebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  String? _projectId;

  final _logController = StreamController<TronAgentLog>.broadcast();
  final _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<TronAgentLog> get logStream => _logController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  bool get isConnected => _isConnected;

  static const String _wsBaseUrl = 'ws://localhost:8080/api/v1';

  void connect(String projectId, {String? token}) {
    _projectId = projectId;
    _doConnect(token);
  }

  void _doConnect(String? token) {
    if (_projectId == null) return;

    try {
      final uri = Uri.parse('$_wsBaseUrl/tron/projects/$_projectId/ws');
      final headers = <String, dynamic>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      _channel = WebSocketChannel.connect(uri, protocols: null);

      _channel!.stream.listen(
        (data) {
          _isConnected = true;
          _handleMessage(data as String);
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          _scheduleReconnect(token);
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect(token);
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _scheduleReconnect(token);
    }
  }

  void _handleMessage(String rawData) {
    try {
      final json = jsonDecode(rawData) as Map<String, dynamic>;
      final type = json['type'] as String?;

      if (type == 'log') {
        final log =
            TronAgentLog.fromJson(json['data'] as Map<String, dynamic>);
        _logController.add(log);
      }

      _eventController.add(json);
    } catch (e) {
      debugPrint('WebSocket parse error: $e');
    }
  }

  void _scheduleReconnect(String? token) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _doConnect(token);
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _projectId = null;
  }

  void dispose() {
    disconnect();
    _logController.close();
    _eventController.close();
  }
}
