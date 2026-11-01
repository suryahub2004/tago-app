import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/vitals_repository.dart';
import 'live_vitals_provider.dart';
import '../../../../core/ble/css_ring/css_ring_service.dart';
import '../../../../core/health/readiness_score.dart';

final vitalsSummaryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  return ref.watch(vitalsRepositoryProvider).getSummary(period: period);
});

final vitalsHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, type) async {
  // Use a default 7d period for history, or it could be parameterized if needed
  return ref.watch(vitalsRepositoryProvider).getHistory(type, period: '7d');
});

final unifiedVitalsProvider = Provider.family<AsyncValue<Map<String, dynamic>>, String>((ref, period) {
  final baseDataAsync = ref.watch(vitalsSummaryProvider(period));

  return baseDataAsync.whenData((baseData) {
    // Create a mutable copy of the map
    final Map<String, dynamic> merged = Map<String, dynamic>.from(baseData);

    // 2. Watch Legacy Live Data
    final live = ref.watch(liveVitalsProvider);
    if (live.hasAnyData) {
      if (live.heartRate != null) merged['avgHr'] = live.heartRate;
      if (live.spo2 != null && live.spo2! > 0) merged['spo2'] = live.spo2;
      if (live.hrv != null && live.hrv! > 0) merged['avgHrv'] = live.hrv;
      if (live.steps != null && live.steps! > 0) merged['steps'] = live.steps;
      if (live.strain != null && live.strain! > 0) merged['strain'] = live.strain;
      if (live.skinTemp != null && live.skinTemp! > 0) merged['skinTemp'] = live.skinTemp;
    }

    // 3. Watch CSS Ring Live Data — merge each category independently
    //    so activity data (steps/calories) appears even before vitals (HR/SpO2).
    final cssRing = ref.watch(cssRingServiceProvider);

    // Vitals (HR, SpO2, HRV, Stress)
    if (cssRing.vitals != null) {
      if (cssRing.vitals!.heartRate > 0) merged['avgHr'] = cssRing.vitals!.heartRate;
      if (cssRing.vitals!.spo2 > 0) merged['spo2'] = cssRing.vitals!.spo2;
      if (cssRing.vitals!.hrv > 0) merged['avgHrv'] = cssRing.vitals!.hrv;
      if (cssRing.vitals!.stress > 0) merged['stress'] = cssRing.vitals!.stress;
    }

    // Activity (Steps, Calories, Distance) — arrives before vitals
    if (cssRing.activity != null) {
      if (cssRing.activity!.steps > 0) merged['steps'] = cssRing.activity!.steps;
      if (cssRing.activity!.calories > 0) merged['calories'] = cssRing.activity!.calories;
      if (cssRing.activity!.distanceKm > 0) merged['distance'] = cssRing.activity!.distanceKm;
    }

    // Blood Pressure
    if (cssRing.bloodPressure != null) {
      merged['bp'] = '${cssRing.bloodPressure!.systolic}/${cssRing.bloodPressure!.diastolic}';
    }

    // Sleep (Sleep Score, Deep, Light, REM, Awake Sleep Time)
    if (cssRing.sleep != null) {
      final total = cssRing.sleep!.totalMinutes;
      merged['sleepScore'] = total > 0 ? (cssRing.sleep!.deepSleepMinutes / total * 100).round() : 0;
      merged['deepSleep'] = cssRing.sleep!.deepSleepMinutes;
      merged['lightSleep'] = cssRing.sleep!.lightSleepMinutes;
      merged['remSleep'] = cssRing.sleep!.remMinutes;
      merged['awakeSleep'] = cssRing.sleep!.awakeMinutes;
      merged['sleepTime'] = total;
    }

    // 4. Calculate readiness score dynamically if missing
    if (merged['readinessScore'] == null && merged['readiness_score'] == null) {
      final double? hrvVal = merged['avgHrv'] != null ? (merged['avgHrv'] as num).toDouble() : null;
      final int? sleepVal = merged['sleepScore'] != null ? (merged['sleepScore'] as num).toInt() : null;
      final int? hrVal = merged['avgHr'] != null ? (merged['avgHr'] as num).toInt() : null;
      final double? strainVal = merged['strain'] != null ? (merged['strain'] as num).toDouble() : null;
      
      // Calculate only if we have at least hrv, sleep, or heart rate data
      if (hrvVal != null || sleepVal != null || hrVal != null) {
        merged['readinessScore'] = ReadinessScore.compute(
          hrv: hrvVal,
          sleepScore: sleepVal,
          restingHr: hrVal,
          strain: strainVal,
        );
      }
    }

    return merged;
  });
});
