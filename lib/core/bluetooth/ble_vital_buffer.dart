import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../network/api_client.dart';
import '../network/network_exception.dart';
import 'package:logger/logger.dart';
import 'ble_models.dart';

class BleVitalBuffer {
  static const _boxName = 'vital_buffer';
  static const _flushThreshold = 100;
  static const _flushInterval = Duration(minutes: 5);

  Box<Map>? _box;
  bool _ready = false;
  final ApiClient _api;
  Timer? _flushTimer;

  BleVitalBuffer(this._api);

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
    _ready = true;
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }

  /// Enqueues a reading. Silently dropped if the Hive box is not yet open
  /// (only possible in the very first milliseconds after launch).
  void add(VitalReading reading) {
    if (!_ready || _box == null) return;
    _box!.add(reading.toJson());
    if (_box!.length >= _flushThreshold) flush();
  }

  Future<void> flush() async {
    if (!_ready || _box == null || _box!.isEmpty) return;
    final readings = _box!.values.take(200).toList();
    try {
      await _api.postMap('/vitals/batch', data: { 'records': readings });
      await _box!.deleteAll(_box!.keys.take(readings.length).toList());
    } on NetworkUnavailableException {
      // Ignored: device offline
    } on Exception catch (e) {
      Logger().e('Vitals flush failed: $e');
    }
  }

  Future<void> forceFlush() async {
    if (!_ready || _box == null) return;
    int prevLen = -1;
    while (_box!.isNotEmpty) {
      await flush();
      if (_box!.length == prevLen) break; // stuck — stop to avoid infinite loop
      prevLen = _box!.length;
    }
  }

  void dispose() => _flushTimer?.cancel();
}
