class BreathingPattern {
  final String id;
  final String name;
  final String description;
  final String category;
  final String iconEmoji;
  final int inhaleSeconds;
  final int hold1Seconds;
  final int exhaleSeconds;
  final int hold2Seconds;
  final int totalCycles;
  final bool? isBreathHold;
  final int? breathHoldTargetSeconds;
  final String? audioGuideAsset;

  BreathingPattern({
    required this.id, required this.name, required this.description, required this.category, required this.iconEmoji,
    required this.inhaleSeconds, required this.hold1Seconds, required this.exhaleSeconds, required this.hold2Seconds,
    required this.totalCycles, this.isBreathHold, this.breathHoldTargetSeconds, this.audioGuideAsset
  });
}

class MeditationSession {
  final String id;
  final String patternId;
  final DateTime startTime;
  final int durationSeconds;
  final double hrvBefore;
  final double hrvAfter;

  MeditationSession({
    required this.id, required this.patternId, required this.startTime, required this.durationSeconds,
    required this.hrvBefore, required this.hrvAfter
  });
}

final List<BreathingPattern> builtInPatterns = [
  BreathingPattern(
    id: 'box',
    name: 'Box Breathing',
    description: 'Navy SEAL technique. Reduces stress, improves focus.',
    category: 'focus',
    iconEmoji: '⬜',
    inhaleSeconds: 4, hold1Seconds: 4, exhaleSeconds: 4, hold2Seconds: 4,
    totalCycles: 8,
  ),
  BreathingPattern(
    id: '478',
    name: '4-7-8 Breathing',
    description: 'Sleep aid. Activates the parasympathetic nervous system.',
    category: 'relaxation',
    iconEmoji: '😴',
    inhaleSeconds: 4, hold1Seconds: 7, exhaleSeconds: 8, hold2Seconds: 0,
    totalCycles: 6,
  ),
  BreathingPattern(
    id: 'physiological_sigh',
    name: 'Physiological Sigh',
    description: 'Double inhale + long exhale. Fastest stress reducer.',
    category: 'relaxation',
    iconEmoji: '😮💨',
    inhaleSeconds: 2, hold1Seconds: 0, exhaleSeconds: 6, hold2Seconds: 0,
    totalCycles: 5,
  ),
  BreathingPattern(
    id: 'wim_hof',
    name: 'Wim Hof Method',
    description: '30 power breaths then breath hold. Advanced — do while sitting.',
    category: 'energising',
    iconEmoji: '❄️',
    inhaleSeconds: 2, hold1Seconds: 0, exhaleSeconds: 2, hold2Seconds: 0,
    totalCycles: 30,
    isBreathHold: true,
    breathHoldTargetSeconds: 60,
  ),
  BreathingPattern(
    id: 'co2_tolerance',
    name: 'CO2 Tolerance',
    description: 'Improve your breath-hold capacity over time.',
    category: 'breath_hold',
    iconEmoji: '⏱️',
    inhaleSeconds: 4, hold1Seconds: 0, exhaleSeconds: 4, hold2Seconds: 0,
    totalCycles: 1,
    isBreathHold: true,
    breathHoldTargetSeconds: 30,
  ),
  BreathingPattern(
    id: 'custom',
    name: 'Custom Pattern',
    description: 'Set your own inhale, hold, exhale, hold durations.',
    category: 'focus',
    iconEmoji: '🎛️',
    inhaleSeconds: 4, hold1Seconds: 4, exhaleSeconds: 4, hold2Seconds: 4,
    totalCycles: 5,
  ),
];
