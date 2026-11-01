class RegisterDto {
  final String name;
  final String email;
  final String password;
  final String phone;
  final DateTime? dateOfBirth;
  final String? gender;

  RegisterDto({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.dateOfBirth,
    this.gender,
  });

  Map<String, dynamic> toJson() {
    // Only send fields that the backend RegisterDto accepts.
    // dateOfBirth and gender belong to HealthProfile and are
    // saved separately via PATCH /users/me/health-profile during onboarding.
    return {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    };
  }
}
