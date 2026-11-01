class AiInsight {
  final String id;
  final String category;
  final String title;
  final String body;
  final String priority;
  final String iconEmoji;
  final String? deepLinkRoute;
  final List<String>? actionItems;
  final String? correlationNote;
  final DateTime generatedAt;
  final int? thumbsUp;
  final int? thumbsDown;
  final bool? userVoted;

  AiInsight({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.priority,
    required this.iconEmoji,
    this.deepLinkRoute,
    this.actionItems,
    this.correlationNote,
    required this.generatedAt,
    this.thumbsUp,
    this.thumbsDown,
    this.userVoted,
  });

  factory AiInsight.fromJson(Map<String, dynamic> json) {
    return AiInsight(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      priority: json['priority'] as String? ?? 'low',
      iconEmoji: json['iconEmoji'] as String? ?? '💡',
      deepLinkRoute: json['deepLinkRoute'] as String?,
      actionItems: json['actionItems'] != null
          ? List<String>.from(json['actionItems'] as List)
          : null,
      correlationNote: json['correlationNote'] as String?,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String) ??
              DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ??
                  DateTime.now()
              : DateTime.now()),
      thumbsUp: json['thumbsUp'] as int?,
      thumbsDown: json['thumbsDown'] as int?,
      userVoted: json['userVoted'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'body': body,
      'priority': priority,
      'iconEmoji': iconEmoji,
      'deepLinkRoute': deepLinkRoute,
      'actionItems': actionItems,
      'correlationNote': correlationNote,
      'generatedAt': generatedAt.toIso8601String(),
      'thumbsUp': thumbsUp,
      'thumbsDown': thumbsDown,
      'userVoted': userVoted,
    };
  }

  AiInsight copyWith({
    String? id,
    String? category,
    String? title,
    String? body,
    String? priority,
    String? iconEmoji,
    String? deepLinkRoute,
    List<String>? actionItems,
    String? correlationNote,
    DateTime? generatedAt,
    int? thumbsUp,
    int? thumbsDown,
    bool? userVoted,
  }) {
    return AiInsight(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      priority: priority ?? this.priority,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      deepLinkRoute: deepLinkRoute ?? this.deepLinkRoute,
      actionItems: actionItems ?? this.actionItems,
      correlationNote: correlationNote ?? this.correlationNote,
      generatedAt: generatedAt ?? this.generatedAt,
      thumbsUp: thumbsUp ?? this.thumbsUp,
      thumbsDown: thumbsDown ?? this.thumbsDown,
      userVoted: userVoted ?? this.userVoted,
    );
  }
}

class WorkoutSuggestion {
  final String type;
  final int durationMinutes;
  final String intensity;

  WorkoutSuggestion({required this.type, required this.durationMinutes, required this.intensity});

  factory WorkoutSuggestion.fromJson(Map<String, dynamic> json) {
    return WorkoutSuggestion(
      type: json['type'] as String? ?? 'Rest',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      intensity: json['intensity'] as String? ?? 'low',
    );
  }
}

class AiCoachResponse {
  final String dailyBrief;
  final List<AiInsight> insights;
  final List<String> todayActions;
  final String readinessMessage;
  final WorkoutSuggestion workoutSuggestion;
  final String generatedAt;
  final bool isCached;

  AiCoachResponse({
    required this.dailyBrief,
    required this.insights,
    required this.todayActions,
    required this.readinessMessage,
    required this.workoutSuggestion,
    required this.generatedAt,
    required this.isCached,
  });

  factory AiCoachResponse.fromJson(Map<String, dynamic> json) {
    // Safely parse workoutSuggestion — returns a sensible default when absent
    final wsSrc = json['workoutSuggestion'] as Map<String, dynamic>?;
    final workoutSuggestion = wsSrc != null
        ? WorkoutSuggestion.fromJson(wsSrc)
        : WorkoutSuggestion(
            type: 'Rest',
            durationMinutes: 0,
            intensity: 'low',
          );

    return AiCoachResponse(
      dailyBrief: json['dailyBrief'] as String? ?? '',
      insights: ((json['insights'] as List?) ?? [])
          .map((i) => AiInsight.fromJson(i as Map<String, dynamic>))
          .toList(),
      todayActions: List<String>.from(
          (json['todayActions'] as List?) ?? const []),
      readinessMessage:
          json['readinessMessage'] as String? ?? '',
      workoutSuggestion: workoutSuggestion,
      generatedAt: json['generatedAt'] as String? ??
          DateTime.now().toIso8601String(),
      isCached: json['isCached'] as bool? ?? false,
    );
  }

  AiCoachResponse copyWith({
    String? dailyBrief,
    List<AiInsight>? insights,
    List<String>? todayActions,
    String? readinessMessage,
    WorkoutSuggestion? workoutSuggestion,
    String? generatedAt,
    bool? isCached,
  }) {
    return AiCoachResponse(
      dailyBrief: dailyBrief ?? this.dailyBrief,
      insights: insights ?? this.insights,
      todayActions: todayActions ?? this.todayActions,
      readinessMessage: readinessMessage ?? this.readinessMessage,
      workoutSuggestion: workoutSuggestion ?? this.workoutSuggestion,
      generatedAt: generatedAt ?? this.generatedAt,
      isCached: isCached ?? this.isCached,
    );
  }
}
