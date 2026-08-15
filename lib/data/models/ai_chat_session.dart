import 'ai_chat_message.dart';

/// AI 易学参详独立会话实体模型
class AiChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<AiChatMessage> messages;

  AiChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    List<AiChatMessage>? messages,
  }) : messages = messages ?? [];

  factory AiChatSession.create({String title = '新易学参详'}) {
    final now = DateTime.now();
    return AiChatSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      title: title,
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }

  factory AiChatSession.fromJson(Map<String, dynamic> json) {
    return AiChatSession(
      id: json['id'] as String? ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? '易学参详',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => AiChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };
}
