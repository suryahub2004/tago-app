import 'css_ring_models.dart';

class CssRingParser {
  static CssRingVitals? parseVitals(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      // 1. Check if it is a JRING live HR packet (starts with 0x14, length >= 6)
      if (bytes[0] == 0x14 && bytes.length >= 6) {
        final heartRate = bytes[5];
        if (heartRate > 30 && heartRate < 200) {
          return CssRingVitals(
            heartRate: heartRate,
            spo2: 0,
            hrv: 0,
            stress: 0,
            timestamp: DateTime.now(),
          );
        }
      }
      
      // 2. Check if it is a Colmi R02 live HR packet (starts with 0x69, length >= 4)
      if (bytes[0] == 0x69 && bytes.length >= 4) {
        final kind = bytes[1]; // 1 = heart rate
        final err = bytes[2];
        final heartRate = bytes[3];
        if (kind == 1 && err == 0 && heartRate > 30 && heartRate < 200) {
          return CssRingVitals(
            heartRate: heartRate,
            spo2: 0,
            hrv: 0,
            stress: 0,
            timestamp: DateTime.now(),
          );
        }
      }

      if (bytes.length < 7) return null; // Require at least 7 bytes for legacy R16/historical HR
      // [6] = heart rate BPM (confirmed from live packets)
      // [5] = flags byte (0x00=normal, 0x01=historical)
      // [17] = HRV / quality score
      // [18] = activity type / stress (if present)
      
      final heartRate = bytes[6];
      final hrv = bytes.length > 17 ? bytes[17] : 0;
      final stress = bytes.length > 18 ? bytes[18] : 0;
      
      // Extract true measurement timestamp (Unix seconds) if we have enough bytes
      DateTime dt = DateTime.now();
      if (bytes.length >= 11) {
        final timestampSec = (bytes[7] << 24) | (bytes[8] << 16) | (bytes[9] << 8) | bytes[10];
        // Sanity check: valid unix time > 1.6 Billion (approx 2020+)
        if (timestampSec > 1600000000) {
          dt = DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);
        }
      }
      
      // SpO2 is NOT in 6E400005 on this ring model
      // Default to 0 until SpO2 characteristic is identified
      const spo2 = 0;

      // Validate — discard impossible values
      if (heartRate < 30 || heartRate > 200) return null;

      return CssRingVitals(
        heartRate: heartRate,
        spo2: spo2,
        hrv: hrv,
        stress: stress,
        timestamp: dt,
      );
    } catch (_) { return null; }
  }

  static CssRingActivity? parseActivity(List<int> bytes) {
    if (bytes.length < 18) return null;
    try {
      // Steps: bytes [4][5] as uint16 BE (NOT uint32)
      // Confirmed: 0x02 0x0B = 523 steps (realistic)
      final steps = (bytes[4] << 8) | bytes[5];

      // Calories: bytes [16][17] as uint16 BE ÷ 10
      // Confirmed: 0x01 0x77 = 375 ÷ 10 = 37.5 kcal
      final rawCalories = (bytes[16] << 8) | bytes[17];
      final calories = rawCalories / 10.0;

      // Distance: byte [13] × 0.1 km
      // 0x0C = 12 × 0.1 = 1.2 km
      final distanceKm = bytes[13] * 0.1;

      // Sanity clamp — realistic daily maximums
      if (steps > 50000) return null; // discard overflow packets
      if (calories > 5000) return null;

      return CssRingActivity(
        steps: steps,
        calories: calories,
        distanceKm: distanceKm,
        timestamp: DateTime.now(),
      );
    } catch (_) { return null; }
  }

  // Sleep response from cmdGetSleep
  static CssRingSleepData? parseSleep(List<int> bytes) {
    if (bytes.length < 8) return null;
    try {
      return CssRingSleepData(
        deepSleepMinutes: (bytes[1] * 60) + bytes[2],
        lightSleepMinutes: (bytes[3] * 60) + bytes[4],
        remMinutes: (bytes[5] * 60) + bytes[6],
        awakeMinutes: bytes[7],
        date: DateTime.now(),
      );
    } catch (_) { return null; }
  }

  // 6E400008: BP systolic=bytes[1], diastolic=bytes[2]
  static CssRingBloodPressure? parseBloodPressure(List<int> bytes) {
    if (bytes.length < 3) return null;
    try {
      final sys = bytes[1]; final dia = bytes[2];
      if (sys < 60 || sys > 250 || dia < 40 || dia > 150) return null;
      return CssRingBloodPressure(
        systolic: sys, diastolic: dia, timestamp: DateTime.now(),
      );
    } catch (_) { return null; }
  }

  static CssRingBattery parseBattery(List<int> bytes) {
    if (bytes.isEmpty) return const CssRingBattery(level: 0, isCharging: false);
    return CssRingBattery(
      level: bytes[0].clamp(0, 100),
      isCharging: bytes.length > 1 && bytes[1] == 0x01,
    );
  }

  static String toHex(List<int> b) =>
      b.map((e) => e.toRadixString(16).padLeft(2,'0').toUpperCase()).join(' ');
}
