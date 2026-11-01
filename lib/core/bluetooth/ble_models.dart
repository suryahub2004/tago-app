class BleParseException implements Exception {
  final String message;
  BleParseException(this.message);
  @override
  String toString() => 'BleParseException: $message';
}

class HeartRateReading {
  final int bpm;
  final DateTime timestamp;
  HeartRateReading({required this.bpm, required this.timestamp});
}

class SpO2Reading {
  final double percentage;
  final double confidence;
  final DateTime timestamp;
  SpO2Reading({required this.percentage, required this.confidence, required this.timestamp});
}

class SkinTempReading {
  final double celsius;
  final double deviationFromBaseline;
  final int quality;
  final DateTime timestamp;
  SkinTempReading({required this.celsius, required this.deviationFromBaseline, required this.quality, required this.timestamp});
}

class StepsReading {
  final int count;
  final double calories;
  final DateTime timestamp;
  StepsReading({required this.count, required this.calories, required this.timestamp});
}

class HrvReading {
  final double sdnn;
  final double rmssd;
  final DateTime timestamp;
  HrvReading({required this.sdnn, required this.rmssd, required this.timestamp});
}

class SleepReading {
  final int score;
  final int totalMinutes;
  final int deepMinutes;
  final int remMinutes;
  final int lightMinutes;
  final int awakeMinutes;
  final int sleepStartMinutesFromMidnight;
  final DateTime timestamp;
  SleepReading({
    required this.score,
    required this.totalMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.lightMinutes,
    required this.awakeMinutes,
    required this.sleepStartMinutesFromMidnight,
    required this.timestamp,
  });
}

class DeviceInfo {
  final String firmwareVersion;
  final String deviceName;
  DeviceInfo({required this.firmwareVersion, required this.deviceName});
}

class RespiratoryRateReading {
  final double breathsPerMinute;
  final double confidence;
  final DateTime timestamp;
  RespiratoryRateReading({required this.breathsPerMinute, required this.confidence, required this.timestamp});
}

class StrainReading {
  final double current;
  final double target;
  final DateTime timestamp;
  StrainReading({required this.current, required this.target, required this.timestamp});
}

class RecoveryReading {
  final int score;
  final int hrvContribution;
  final int sleepContribution;
  final DateTime timestamp;
  RecoveryReading({required this.score, required this.hrvContribution, required this.sleepContribution, required this.timestamp});
}

class Vo2MaxReading {
  final double value;
  final DateTime timestamp;
  Vo2MaxReading({required this.value, required this.timestamp});
}

class CaloriesReading {
  final double active;
  final double resting;
  final DateTime timestamp;
  CaloriesReading({required this.active, required this.resting, required this.timestamp});
}

class VitalReading {
  final String metricType;
  final num value;
  final DateTime timestamp;
  final Map<String, dynamic>? extra;
  /// The BLE device MAC / remote ID that produced this reading.
  /// Populated by BleManager when a notification arrives from a connected device.
  final String? deviceSerial;

  VitalReading({
    required this.metricType,
    required this.value,
    required this.timestamp,
    this.extra,
    this.deviceSerial,
  });

  factory VitalReading.fromHeartRate(HeartRateReading r, {String? deviceSerial}) =>
      VitalReading(metricType: 'heart_rate', value: r.bpm, timestamp: r.timestamp, deviceSerial: deviceSerial);
  factory VitalReading.fromSpO2(SpO2Reading r, {String? deviceSerial}) =>
      VitalReading(metricType: 'spo2', value: r.percentage, timestamp: r.timestamp, extra: {'confidence': r.confidence}, deviceSerial: deviceSerial);
  factory VitalReading.fromSkinTemp(SkinTempReading r, {String? deviceSerial}) =>
      VitalReading(metricType: 'skin_temp', value: r.celsius, timestamp: r.timestamp, extra: {'deviation': r.deviationFromBaseline, 'quality': r.quality}, deviceSerial: deviceSerial);
  factory VitalReading.fromSteps(StepsReading r, {String? deviceSerial}) =>
      VitalReading(metricType: 'steps', value: r.count, timestamp: r.timestamp, extra: {'calories': r.calories}, deviceSerial: deviceSerial);
  factory VitalReading.fromHrv(HrvReading r, {String? deviceSerial}) =>
      VitalReading(metricType: 'hrv', value: r.rmssd, timestamp: r.timestamp, extra: {'sdnn': r.sdnn}, deviceSerial: deviceSerial);
  factory VitalReading.fromSleep(SleepReading r, {String? deviceSerial}) =>
      VitalReading(metricType: 'sleep', value: r.score, timestamp: r.timestamp, deviceSerial: deviceSerial, extra: {
        'totalMinutes': r.totalMinutes,
        'deepMinutes': r.deepMinutes,
        'remMinutes': r.remMinutes,
        'lightMinutes': r.lightMinutes,
        'awakeMinutes': r.awakeMinutes,
        'sleepStart': r.sleepStartMinutesFromMidnight,
      });
  factory VitalReading.fromRespiratoryRate(RespiratoryRateReading r, {String? deviceSerial}) =>
      VitalReading(metricType: 'respiratory_rate', value: r.breathsPerMinute, timestamp: r.timestamp, extra: {'confidence': r.confidence}, deviceSerial: deviceSerial);
  factory VitalReading.fromStrain(StrainReading r, {String? deviceSerial}) =>
      VitalReading(metricType: 'strain', value: r.current, timestamp: r.timestamp, extra: {'target': r.target}, deviceSerial: deviceSerial);
  factory VitalReading.fromRecovery(RecoveryReading r, {String? deviceSerial}) =>
      VitalReading(metricType: 'recovery', value: r.score, timestamp: r.timestamp, extra: {'hrvContribution': r.hrvContribution, 'sleepContribution': r.sleepContribution}, deviceSerial: deviceSerial);
  factory VitalReading.fromCalories(CaloriesReading r, {String? deviceSerial}) =>
      VitalReading(metricType: 'calories', value: r.active + r.resting, timestamp: r.timestamp, extra: {'active': r.active, 'resting': r.resting}, deviceSerial: deviceSerial);

  Map<String, dynamic> toJson() => {
    'metricType': metricType,
    'value': value,
    'timestamp': timestamp.toIso8601String(),
    if (deviceSerial != null) 'deviceSerial': deviceSerial,
    if (extra != null) 'extra': extra,
  };
}
