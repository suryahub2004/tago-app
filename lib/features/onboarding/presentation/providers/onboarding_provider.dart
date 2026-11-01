import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/auth_state.dart';

final onboardingProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
      return OnboardingController();
    });

class OnboardingState {
  const OnboardingState({
    this.deviceType,
    this.step = 0,
    this.fullName = '',
    this.age = 32,
    this.gender = 'Prefer not to say',
    this.heightCm = 172,
    this.weightKg = 70,
    this.fitnessLevel = 'Active',
    this.primaryGoal = 'General Wellness',
    this.activeDays = 4,
    this.sleepQuality = 7,
    this.healthSyncEnabled = false,
  });

  final DeviceType? deviceType;
  final int step;
  final String fullName;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String fitnessLevel;
  final String primaryGoal;
  final int activeDays;
  final int sleepQuality;
  final bool healthSyncEnabled;

  OnboardingState copyWith({
    DeviceType? deviceType,
    int? step,
    String? fullName,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? fitnessLevel,
    String? primaryGoal,
    int? activeDays,
    int? sleepQuality,
    bool? healthSyncEnabled,
  }) {
    return OnboardingState(
      deviceType: deviceType ?? this.deviceType,
      step: step ?? this.step,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      activeDays: activeDays ?? this.activeDays,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(const OnboardingState());

  void setDeviceType(DeviceType type) =>
      state = state.copyWith(deviceType: type);
  void setStep(int step) => state = state.copyWith(step: step.clamp(0, 6));
  void setFullName(String value) => state = state.copyWith(fullName: value);
  void setAge(double value) => state = state.copyWith(age: value.round());
  void setGender(String value) => state = state.copyWith(gender: value);
  void setHeight(double value) => state = state.copyWith(heightCm: value);
  void setWeight(double value) => state = state.copyWith(weightKg: value);
  void setFitnessLevel(String value) =>
      state = state.copyWith(fitnessLevel: value);
  void setPrimaryGoal(String value) =>
      state = state.copyWith(primaryGoal: value);
  void setActiveDays(double value) =>
      state = state.copyWith(activeDays: value.round());
  void setSleepQuality(double value) =>
      state = state.copyWith(sleepQuality: value.round());
  void setHealthSyncEnabled(bool value) =>
      state = state.copyWith(healthSyncEnabled: value);
}
