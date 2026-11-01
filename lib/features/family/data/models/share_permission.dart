class SharePermission {
  final bool heartRate;
  final bool hrv;
  final bool spo2;
  final bool skinTemperature;
  final bool sleepScore;
  final bool sleepStages;
  final bool steps;
  final bool calories;
  final bool strain;
  final bool vo2Max;
  final bool stressLevel;
  final bool cycleTracking;
  final bool deviceBattery;
  final bool lastActive;
  final bool alerts;
  final String? silentHoursStart;
  final String? silentHoursEnd;

  SharePermission({
    this.heartRate = true,
    this.hrv = true,
    this.spo2 = true,
    this.skinTemperature = false,
    this.sleepScore = true,
    this.sleepStages = false,
    this.steps = true,
    this.calories = false,
    this.strain = false,
    this.vo2Max = false,
    this.stressLevel = true,
    this.cycleTracking = false,
    this.deviceBattery = true,
    this.lastActive = true,
    this.alerts = true,
    this.silentHoursStart,
    this.silentHoursEnd,
  });

  factory SharePermission.fromJson(Map<String, dynamic> json) {
    return SharePermission(
      heartRate: json['heartRate'] ?? true,
      hrv: json['hrv'] ?? true,
      spo2: json['spo2'] ?? true,
      skinTemperature: json['skinTemperature'] ?? false,
      sleepScore: json['sleepScore'] ?? true,
      sleepStages: json['sleepStages'] ?? false,
      steps: json['steps'] ?? true,
      calories: json['calories'] ?? false,
      strain: json['strain'] ?? false,
      vo2Max: json['vo2Max'] ?? false,
      stressLevel: json['stressLevel'] ?? true,
      cycleTracking: json['cycleTracking'] ?? false,
      deviceBattery: json['deviceBattery'] ?? true,
      lastActive: json['lastActive'] ?? true,
      alerts: json['alerts'] ?? true,
      silentHoursStart: json['silentHoursStart'],
      silentHoursEnd: json['silentHoursEnd'],
    );
  }
}
