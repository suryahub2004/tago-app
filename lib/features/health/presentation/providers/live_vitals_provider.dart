import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/bluetooth/ble_manager.dart';
import '../../../../core/bluetooth/ble_models.dart';

/// Holds the latest reading for each vital metric received live from BLE.
/// Updated in real-time as notifications arrive from the ring/band.
class LiveVitals {
  const LiveVitals({
    this.heartRate,
    this.spo2,
    this.hrv,
    this.skinTemp,
    this.steps,
    this.strain,
    this.respiratoryRate,
    this.recovery,
    this.calories,
    this.battery,
  });

  final int? heartRate;       // bpm
  final double? spo2;         // percentage
  final double? hrv;          // RMSSD ms
  final double? skinTemp;     // celsius
  final int? steps;           // count
  final double? strain;       // 0–21
  final double? respiratoryRate;
  final int? recovery;        // 0–100
  final double? calories;
  final int? battery;         // 0–100

  LiveVitals copyWith({
    int? heartRate,
    double? spo2,
    double? hrv,
    double? skinTemp,
    int? steps,
    double? strain,
    double? respiratoryRate,
    int? recovery,
    double? calories,
    int? battery,
  }) {
    return LiveVitals(
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      hrv: hrv ?? this.hrv,
      skinTemp: skinTemp ?? this.skinTemp,
      steps: steps ?? this.steps,
      strain: strain ?? this.strain,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      recovery: recovery ?? this.recovery,
      calories: calories ?? this.calories,
      battery: battery ?? this.battery,
    );
  }

  bool get hasAnyData =>
      heartRate != null ||
      spo2 != null ||
      hrv != null ||
      steps != null;
}

/// StateNotifier that subscribes to BleManager.vitals stream and
/// updates LiveVitals state as readings arrive from the connected device.
class LiveVitalsNotifier extends StateNotifier<LiveVitals> {
  LiveVitalsNotifier(this._bleManager) : super(const LiveVitals()) {
    _subscribe();
  }

  final BleManager _bleManager;
  StreamSubscription<VitalReading>? _sub;

  void _subscribe() {
    _sub = _bleManager.vitals.listen(_onReading);
  }

  void _onReading(VitalReading reading) {
    switch (reading.metricType) {
      case 'heart_rate':
        state = state.copyWith(heartRate: (reading.value).toInt());
      case 'spo2':
        state = state.copyWith(spo2: (reading.value).toDouble());
      case 'hrv':
        state = state.copyWith(hrv: (reading.value).toDouble());
      case 'skin_temp':
        state = state.copyWith(skinTemp: (reading.value).toDouble());
      case 'steps':
        state = state.copyWith(steps: (reading.value).toInt());
      case 'strain':
        state = state.copyWith(strain: (reading.value).toDouble());
      case 'respiratory_rate':
        state = state.copyWith(
            respiratoryRate: (reading.value).toDouble());
      case 'recovery':
        state = state.copyWith(recovery: (reading.value).toInt());
      case 'calories':
        state = state.copyWith(calories: (reading.value).toDouble());
      case 'battery':
        state = state.copyWith(battery: (reading.value).toInt());
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Global provider — watch this anywhere in the app to get live BLE readings.
/// Returns [LiveVitals] which has nullable fields for each metric.
/// If the device is not connected, all fields are null.
final liveVitalsProvider =
    StateNotifierProvider<LiveVitalsNotifier, LiveVitals>((ref) {
  final bleManager = ref.watch(bleManagerProvider);
  return LiveVitalsNotifier(bleManager);
});
