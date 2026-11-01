class AlertModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isAcknowledged;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isAcknowledged,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Alert',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      isAcknowledged: json['isAcknowledged'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
