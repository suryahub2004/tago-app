class VitalsSummary {
  const VitalsSummary({
    required this.heartRate,
    required this.hrv,
    required this.spo2,
    required this.steps,
    required this.sleepScore,
    this.readinessScore,
    this.strain,
    this.skinTemp,
  });

  final double heartRate;
  final double hrv;
  final double spo2;
  final int steps;
  final double sleepScore;
  final int? readinessScore;
  final double? strain;
  final double? skinTemp;

  factory VitalsSummary.fromJson(Map<String, dynamic> json) {
    return VitalsSummary(
      heartRate: (json['heartRate'] as num? ?? json['avgHr'] as num? ?? json['heart_rate'] as num? ?? 0).toDouble(),
      hrv: (json['hrv'] as num? ?? json['avgHrv'] as num? ?? 0).toDouble(),
      spo2: (json['spo2'] as num? ?? 0).toDouble(),
      steps: (json['steps'] as num? ?? 0).toInt(),
      sleepScore: (json['sleepScore'] as num? ?? json['sleep_score'] as num? ?? 0).toDouble(),
      readinessScore: (json['readinessScore'] as num? ?? json['readiness_score'] as num?)?.toInt(),
      strain: (json['strain'] as num?)?.toDouble() ?? 0.0,
      skinTemp: (json['skinTemp'] as num? ?? json['skin_temp'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'heartRate': heartRate,
    'hrv': hrv,
    'spo2': spo2,
    'steps': steps,
    'sleepScore': sleepScore,
    'readinessScore': readinessScore,
    'strain': strain,
    'skinTemp': skinTemp,
  };

  VitalsSummary copyWith({
    double? heartRate,
    double? hrv,
    double? spo2,
    int? steps,
    double? sleepScore,
    int? readinessScore,
    double? strain,
    double? skinTemp,
  }) {
    return VitalsSummary(
      heartRate: heartRate ?? this.heartRate,
      hrv: hrv ?? this.hrv,
      spo2: spo2 ?? this.spo2,
      steps: steps ?? this.steps,
      sleepScore: sleepScore ?? this.sleepScore,
      readinessScore: readinessScore ?? this.readinessScore,
      strain: strain ?? this.strain,
      skinTemp: skinTemp ?? this.skinTemp,
    );
  }

}
