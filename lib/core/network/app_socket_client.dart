import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final appSocketClientProvider = Provider<AppSocketClient>((ref) {
  final client = AppSocketClient();
  ref.onDispose(() => client.dispose());
  return client;
});

class AppSocketClient {
  AppSocketClient();

  io.Socket? _socket;
  
  final _adminBroadcastController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get adminBroadcastStream => _adminBroadcastController.stream;

  final _anomalyController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get anomalyStream => _anomalyController.stream;

  Future<void> connect(String token) async {
    if (_socket != null && _socket!.connected) return;

    final String rawBaseUrl = dotenv.maybeGet('API_BASE_URL') ?? 'https://api.smartvital.io/api/v1';
    final baseUrl = rawBaseUrl.replaceAll('/api/v1', '');
    
    _socket = io.io('$baseUrl/app', io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build());

    _socket!.onConnect((_) {
      debugPrint('Connected to App Socket (/app namespace)');
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from App Socket');
    });

    _socket!.on('popup_message', (data) {
      if (data is Map<String, dynamic>) {
        _adminBroadcastController.add({
          'title': data['title']?.toString() ?? 'Notice',
          'body': data['body']?.toString() ?? '',
          'type': data['type']?.toString(),
          'actionLabel': data['actionLabel']?.toString(),
          'actionUrl': data['actionUrl']?.toString(),
        });
      }
    });

    _socket!.on('vitals_anomaly', (data) {
      if (data is Map<String, dynamic>) {
        _anomalyController.add(data);
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _adminBroadcastController.close();
    _anomalyController.close();
  }
}
