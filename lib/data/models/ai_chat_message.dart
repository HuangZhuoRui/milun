/// AI 对话消息实体模型（支持持久化与上下文多轮对话）
class AiChatMessage {
  final String id;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final String? reasoningContent; // R1 思考推理链
  final DateTime timestamp;
  final List<String> profileNames; // 该条消息所附带的命盘人员名称

  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.reasoningContent,
    required this.timestamp,
    this.profileNames = const [],
  });

  AiChatMessage copyWith({
    String? content,
    String? reasoningContent,
  }) {
    return AiChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      reasoningContent: reasoningContent ?? this.reasoningContent,
      timestamp: timestamp,
      profileNames: profileNames,
    );
  }

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      reasoningContent: json['reasoningContent'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      profileNames: (json['profileNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'reasoningContent': reasoningContent,
        'timestamp': timestamp.toIso8601String(),
        'profileNames': profileNames,
      };
}
