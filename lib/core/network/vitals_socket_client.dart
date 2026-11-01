import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../storage/secure_storage.dart';

final vitalsSocketProvider = Provider<VitalsSocketClient>((ref) {
  return VitalsSocketClient(ref.watch(secureStorageProvider));
});

class VitalsSocketClient {
  VitalsSocketClient(this._storage);

  final SecureStorage _storage;
  io.Socket? _socket;
  
  final _vitalsStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get vitalsStream => _vitalsStreamController.stream;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _storage.read(SecureStorage.accessTokenKey);
    if (token == null) return;

    // Use baseUrl but append /family namespace
    final String rawBaseUrl = dotenv.maybeGet('API_BASE_URL') ?? 'https://api.smartvital.io/api/v1';
    final baseUrl = rawBaseUrl.replaceAll('/api/v1', '');
    
    _socket = io.io('$baseUrl/family', io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build());

    _socket!.onConnect((_) {
      debugPrint('Connected to Family Socket');
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from Family Socket');
    });

    _socket!.on('vital_update', (data) {
      if (data is Map<String, dynamic>) {
        _vitalsStreamController.add(data);
      }
    });
  }

  void subscribeToFamilyGroup(String familyGroupId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('subscribe_family', {'familyGroupId': familyGroupId});
    }
  }

  void unsubscribeFromFamilyGroup(String familyGroupId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('unsubscribe_family', {'familyGroupId': familyGroupId});
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
