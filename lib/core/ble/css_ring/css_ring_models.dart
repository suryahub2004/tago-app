class CssRingVitals {
  final int heartRate;
  final int spo2;
  final int hrv;
  final int stress;
  final DateTime timestamp;
  const CssRingVitals({
    required this.heartRate, required this.spo2,
    required this.hrv, required this.stress,
    required this.timestamp,
  });
  bool get isValid => heartRate > 30 && heartRate < 200;
}

class CssRingActivity {
  final int steps;
  final double calories;
  final double distanceKm;
  final DateTime timestamp;
  const CssRingActivity({
    required this.steps, required this.calories,
    required this.distanceKm, required this.timestamp,
  });
}

class CssRingSleepData {
  final int deepSleepMinutes;
  final int lightSleepMinutes;
  final int remMinutes;
  final int awakeMinutes;
  final DateTime date;
  int get totalMinutes => deepSleepMinutes + lightSleepMinutes + remMinutes;
  const CssRingSleepData({
    required this.deepSleepMinutes, required this.lightSleepMinutes,
    required this.remMinutes, required this.awakeMinutes,
    required this.date,
  });
}

class CssRingBloodPressure {
  final int systolic;
  final int diastolic;
  final DateTime timestamp;
  const CssRingBloodPressure({
    required this.systolic, required this.diastolic,
    required this.timestamp,
  });
}

class CssRingBattery {
  final int level;
  final bool isCharging;
  const CssRingBattery({required this.level, required this.isCharging});
}

class CssRingState {
  final bool isConnected;
  final bool isConnecting;
  final bool isMonitoring;
  final int? liveHeartRate;
  final CssRingVitals? vitals;
  final CssRingActivity? activity;
  final CssRingSleepData? sleep;
  final CssRingBloodPressure? bloodPressure;
  final CssRingBattery? battery;
  final String? error;

  const CssRingState({
    this.isConnected = false,
    this.isConnecting = false,
    this.isMonitoring = false,
    this.liveHeartRate,
    this.vitals,
    this.activity,
    this.sleep,
    this.bloodPressure,
    this.battery,
    this.error,
  });

  CssRingState copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isMonitoring,
    int? liveHeartRate,
    bool clearLiveHeartRate = false,
    CssRingVitals? vitals,
    CssRingActivity? activity,
    CssRingSleepData? sleep,
    CssRingBloodPressure? bloodPressure,
    CssRingBattery? battery,
    String? error,
  }) => CssRingState(
    isConnected: isConnected ?? this.isConnected,
    isConnecting: isConnecting ?? this.isConnecting,
    isMonitoring: isMonitoring ?? this.isMonitoring,
    liveHeartRate: clearLiveHeartRate ? null : (liveHeartRate ?? this.liveHeartRate),
    vitals: vitals ?? this.vitals,
    activity: activity ?? this.activity,
    sleep: sleep ?? this.sleep,
    bloodPressure: bloodPressure ?? this.bloodPressure,
    battery: battery ?? this.battery,
    error: error,
  );
}
