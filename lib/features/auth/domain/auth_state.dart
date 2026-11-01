enum UserRole { healthUser, parentGuardian }

enum DeviceType { ring, band, both }

class HealthProfile {
  const HealthProfile({
    this.deviceType,
    this.onboardingComplete = false,
    this.fitnessLevel = 'Active',
    this.primaryGoal = 'General wellness',
    this.age = 32,
    this.healthSyncEnabled = false,
  });

  final DeviceType? deviceType;
  final bool onboardingComplete;
  final String fitnessLevel;
  final String primaryGoal;
  final int age;
  final bool healthSyncEnabled;

  HealthProfile copyWith({
    DeviceType? deviceType,
    bool? onboardingComplete,
    String? fitnessLevel,
    String? primaryGoal,
    int? age,
    bool? healthSyncEnabled,
  }) {
    return HealthProfile(
      deviceType: deviceType ?? this.deviceType,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      age: age ?? this.age,
      healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
    );
  }

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      deviceType: _deviceTypeFromJson(json['deviceType'] as String?),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      fitnessLevel: json['fitnessLevel'] as String? ?? 'Active',
      primaryGoal: json['primaryGoal'] as String? ?? 'General wellness',
      age: json['age'] as int? ?? 32,
      healthSyncEnabled: json['healthSyncEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceType': deviceType?.name,
    'onboardingComplete': onboardingComplete,
    'fitnessLevel': fitnessLevel,
    'primaryGoal': primaryGoal,
    'age': age,
    'healthSyncEnabled': healthSyncEnabled,
  };
}

class SmartVitalUser {
  const SmartVitalUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.healthProfile,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final HealthProfile healthProfile;
  final String? phone;
  final String? avatarUrl;

  String get firstName => fullName.trim().split(' ').first;

  SmartVitalUser copyWith({
    String? fullName,
    String? email,
    UserRole? role,
    HealthProfile? healthProfile,
    String? phone,
    String? avatarUrl,
  }) {
    return SmartVitalUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      healthProfile: healthProfile ?? this.healthProfile,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory SmartVitalUser.fromJson(Map<String, dynamic> json) {
    return SmartVitalUser(
      id: json['id'] as String? ?? 'me',
      fullName:
          json['fullName'] as String? ??
          json['name'] as String? ??
          'SmartVital Member',
      email: json['email'] as String? ?? 'member@smartvital.io',
      phone: json['phone'] as String?,
      role: json['role'] == 'parentGuardian'
          ? UserRole.parentGuardian
          : UserRole.healthUser,
      avatarUrl: json['avatarUrl'] as String?,
      healthProfile: HealthProfile.fromJson(
        Map<String, dynamic>.from(json['healthProfile'] as Map? ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'role': role.name,
    'avatarUrl': avatarUrl,
    'healthProfile': healthProfile.toJson(),
  };
}

class AuthState {
  const AuthState({
    this.user,
    this.isRestoring = true,
    this.isLoading = false,
    this.errorMessage,
  });

  final SmartVitalUser? user;
  final bool isRestoring;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;
  bool get onboardingComplete =>
      user?.healthProfile.onboardingComplete ?? false;

  AuthState copyWith({
    SmartVitalUser? user,
    bool clearUser = false,
    bool? isRestoring,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isRestoring: isRestoring ?? this.isRestoring,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

DeviceType? _deviceTypeFromJson(String? value) {
  return switch (value) {
    'ring' => DeviceType.ring,
    'band' => DeviceType.band,
    'both' => DeviceType.both,
    _ => null,
  };
}
