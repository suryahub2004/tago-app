import 'package:flutter/material.dart';

/// Computes a 0–100 readiness score from previous-day vitals.
/// Algorithm:
///   - HRV contribution (40%): normalize RMSSD 20–120ms → 0–100
///   - Sleep contribution (30%): sleep score is already 0–100
///   - Resting HR contribution (20%): normalize 40–100 bpm → 100–0 (lower HR = better)
///   - Strain penalty (10%): normalize strain 0–21 → subtract 0–10 points
class ReadinessScore {
  static int compute({
    required double? hrv,        // RMSSD in ms (null if unavailable)
    required int? sleepScore,    // 0–100 (null if unavailable)
    required int? restingHr,     // bpm (null if unavailable)
    required double? strain,     // 0–21 scale (null if unavailable)
  }) {
    double score = 50.0; // default when no data
    double weightUsed = 0.0;

    if (hrv != null) {
      final hrvScore = ((hrv - 20.0) / (120.0 - 20.0)).clamp(0.0, 1.0) * 100.0;
      score = (score * weightUsed + hrvScore * 0.40) / (weightUsed + 0.40);
      weightUsed += 0.40;
    }
    if (sleepScore != null) {
      final sleep = sleepScore.toDouble().clamp(0.0, 100.0);
      score = (score * weightUsed + sleep * 0.30) / (weightUsed + 0.30);
      weightUsed += 0.30;
    }
    if (restingHr != null) {
      final hrScore = (1.0 - ((restingHr - 40.0) / (100.0 - 40.0)).clamp(0.0, 1.0)) * 100.0;
      score = (score * weightUsed + hrScore * 0.20) / (weightUsed + 0.20);
      weightUsed += 0.20;
    }
    if (strain != null) {
      final penalty = (strain / 21.0).clamp(0.0, 1.0) * 10.0;
      score = (score - penalty).clamp(0.0, 100.0);
    }

    return score.round().clamp(0, 100);
  }

  static String label(int score) {
    if (score >= 80) return 'Optimal';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Moderate';
    return 'Low';
  }

  static Color color(int score, {required bool darkMode}) {
    if (score >= 80) return const Color(0xFF4CAF50); // green
    if (score >= 60) return const Color(0xFFFFC107); // amber
    if (score >= 40) return const Color(0xFFFF9800); // orange
    return const Color(0xFFF44336);                  // red
  }
}
