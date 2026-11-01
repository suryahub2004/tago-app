class FamilyInvite {
  final String id;
  final String token;
  final String inviteUrl;
  final String? email;
  final String status;

  FamilyInvite({
    required this.id, required this.token, required this.inviteUrl, this.email, required this.status
  });

  factory FamilyInvite.fromJson(Map<String, dynamic> json) {
    return FamilyInvite(
      id: json['id'],
      token: json['token'],
      inviteUrl: json['inviteUrl'],
      email: json['email'],
      status: json['status'],
    );
  }
}
