class ChatMessage {
  final String id;
  final String role; // user | model | system (system opcional)
  final String text;
  final DateTime createdAt;
  final bool streaming; // true si se está construyendo
  final bool error;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.streaming = false,
    this.error = false,
  });

  ChatMessage copyWith({
    String? id,
    String? role,
    String? text,
    DateTime? createdAt,
    bool? streaming,
    bool? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      streaming: streaming ?? this.streaming,
      error: error ?? this.error,
    );
  }
}