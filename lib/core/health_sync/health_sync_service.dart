import 'package:health/health.dart';

import '../bluetooth/ble_models.dart';
import 'health_sync_models.dart';

class HealthSyncService {
  HealthSyncService() : _health = Health();

  final Health _health;

  Future<bool> requestPermissions() async {
    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.HEART_RATE_VARIABILITY_SDNN,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.BODY_TEMPERATURE,
      HealthDataType.RESPIRATORY_RATE,
      HealthDataType.WORKOUT,
    ];
    final permissions = types.map((_) => HealthDataAccess.READ_WRITE).toList();
    return _health.requestAuthorization(types, permissions: permissions);
  }

  Future<HealthSyncResult> syncFromPlatform() async {
    return const HealthSyncResult(enabled: true, syncedCount: 0);
  }

  Future<void> writeToPlatform(List<VitalReading> readings) async {}
}
