import 'share_permission.dart';

class FamilyMember {
  final String id;
  final String userId;
  final String name;
  final String relation;
  final String? avatarUrl;
  final String deviceType;
  final String status;
  final int? latestHr;
  final int? latestSpo2;
  final SharePermission permissions;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.relation,
    this.avatarUrl,
    this.deviceType = 'Ring',
    this.status = 'Normal',
    this.latestHr,
    this.latestSpo2,
    required this.permissions,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    // Backend returns Prisma FamilyMember shape where the actual user data
    // is nested under the 'member' key. We support both the flat shape
    // (cached/local) and the nested Prisma shape transparently.
    final nested = json['member'] as Map<String, dynamic>?;

    return FamilyMember(
      id: json['id'] as String? ?? '',
      // memberUserId is the FK in the Prisma join table; fallback to nested id
      userId: json['memberUserId'] as String?
          ?? nested?['id'] as String?
          ?? json['userId'] as String?
          ?? '',
      // Name lives inside nested 'member' object in the Prisma response
      name: nested?['name'] as String?
          ?? json['name'] as String?
          ?? '',
      avatarUrl: nested?['avatarUrl'] as String?
          ?? json['avatarUrl'] as String?,
      // Prisma uses 'relationship'; local cache uses 'relation'
      relation: json['relationship'] as String?
          ?? json['relation'] as String?
          ?? 'Member',
      deviceType: json['deviceType'] as String? ?? 'Ring',
      status: json['status'] as String? ?? 'Normal',
      latestHr: json['latestHr'] as int?,
      latestSpo2: json['latestSpo2'] as int?,
      permissions: SharePermission.fromJson(
        (json['permissions'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  FamilyMember copyWith({
    String? id,
    String? userId,
    String? name,
    String? relation,
    String? avatarUrl,
    String? deviceType,
    String? status,
    int? latestHr,
    int? latestSpo2,
    SharePermission? permissions,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      deviceType: deviceType ?? this.deviceType,
      status: status ?? this.status,
      latestHr: latestHr ?? this.latestHr,
      latestSpo2: latestSpo2 ?? this.latestSpo2,
      permissions: permissions ?? this.permissions,
    );
  }
}
