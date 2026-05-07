enum ChatRole { user, assistant, system }

ChatRole _parseRole(String role) {
  return switch (role) {
    'user' => ChatRole.user,
    'assistant' => ChatRole.assistant,
    'system' => ChatRole.system,
    _ => ChatRole.assistant,
  };
}

class ChatMessage {
  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    this.model,
    this.createdAt,
    this.pending = false,
  });

  final int? id;
  final ChatRole role;
  final String content;
  final String? model;
  final DateTime? createdAt;
  final bool pending;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as int?,
        role: _parseRole((json['role'] as String?) ?? 'assistant'),
        content: json['content'] as String? ?? '',
        model: json['model'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  ChatMessage copyWith({String? content, bool? pending}) => ChatMessage(
        id: id,
        role: role,
        content: content ?? this.content,
        model: model,
        createdAt: createdAt,
        pending: pending ?? this.pending,
      );
}
