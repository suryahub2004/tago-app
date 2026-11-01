import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

import '../bluetooth/ble_models.dart';

final appleHealthServiceProvider = Provider<AppleHealthService>((ref) {
  return AppleHealthService();
});

class AppleHealthService {
  final Health _health = Health();

  bool _isAuthorized = false;

  Future<bool> requestPermissions() async {
    if (!Platform.isIOS) return false;

    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.STEPS,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    ];

    try {
      final permissions = List<HealthDataAccess>.filled(types.length, HealthDataAccess.READ_WRITE);
      _isAuthorized = await _health.requestAuthorization(types, permissions: permissions);
      return _isAuthorized;
    } catch (e) {
      debugPrint('Error requesting Apple Health permissions: $e');
      return false;
    }
  }

  Future<void> syncVitalReading(VitalReading reading) async {
    if (!Platform.isIOS || !_isAuthorized) return;

    try {
      final now = reading.timestamp;
      
      switch (reading.metricType) {
        case 'heart_rate':
          await _health.writeHealthData(
            value: reading.value.toDouble(),
            type: HealthDataType.HEART_RATE,
            startTime: now.subtract(const Duration(seconds: 1)),
            endTime: now,
          );
          break;
        case 'steps':
          await _health.writeHealthData(
            value: reading.value.toDouble(),
            type: HealthDataType.STEPS,
            startTime: now.subtract(const Duration(seconds: 1)),
            endTime: now,
          );
          break;
        case 'spo2':
          await _health.writeHealthData(
            value: (reading.value / 100.0).toDouble(), // HealthKit expects 0.0 - 1.0 for percentage
            type: HealthDataType.BLOOD_OXYGEN,
            startTime: now.subtract(const Duration(seconds: 1)),
            endTime: now,
          );
          break;
        case 'sleep':
          // The VitalReading for sleep currently just passes deep+light in value.
          // To properly write sleep, we would ideally write start/end times.
          // Since we just get a summary from the ring, we can write a single block of "In Bed".
          await _health.writeHealthData(
            value: 0, // value is ignored for SLEEP_IN_BED, start/end times are what matter
            type: HealthDataType.SLEEP_IN_BED,
            startTime: now.subtract(Duration(minutes: reading.value.toInt())),
            endTime: now,
          );
          break;
      }
    } catch (e) {
      debugPrint('Error writing to Apple Health: $e');
    }
  }
}
