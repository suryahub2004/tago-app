class MemberComparison {
  final String name;
  final int steps;
  final int sleep;
  final int heartRate;
  final int spo2;

  MemberComparison({
    required this.name,
    required this.steps,
    required this.sleep,
    this.heartRate = 0,
    this.spo2 = 0,
  });

  factory MemberComparison.fromJson(Map<String, dynamic> json) {
    return MemberComparison(
      name:      json['name'] as String? ?? '',
      steps:     (json['steps']     as num?)?.toInt() ?? 0,
      sleep:     (json['sleep']     as num?)?.toInt() ?? 0,
      heartRate: (json['heartRate'] as num?)?.toInt() ?? 0,
      spo2:      (json['spo2']      as num?)?.toInt() ?? 0,
    );
  }
}

class FamilyChallenge {
  final String id;
  final String title;
  final String description;
  final String type;
  final int target;
  final String endDate;
  final List<Map<String, dynamic>> participants;

  FamilyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.endDate,
    required this.participants,
  });

  factory FamilyChallenge.fromJson(Map<String, dynamic> json) {
    return FamilyChallenge(
      id:          json['id'] as String? ?? '',
      title:       json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type:        json['type'] as String? ?? 'STEPS',
      target:      (json['target'] as num?)?.toInt() ?? 10000,
      endDate:     json['endDate'] as String? ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}
