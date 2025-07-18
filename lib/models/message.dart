import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant, system }

extension MessageRoleExtension on MessageRole {
  String get name {
    switch (this) {
      case MessageRole.user:
        return 'User';
      case MessageRole.assistant:
        return 'Assistant';
      case MessageRole.system:
        return 'System';
    }
  }
}

class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final String? imageBase64;
  final List<double>? embedding;

  Message({
    String? id,
    required this.role,
    required this.content,
    this.imageBase64,
    this.embedding,
    DateTime? timestamp,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  Message copyWith({
    String? id,
    MessageRole? role,
    String? content,
    String? imageBase64,
    List<double>? embedding,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      imageBase64: imageBase64 ?? this.imageBase64,
      embedding: embedding ?? this.embedding,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.toString().split('.').last,
      'content': content,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (embedding != null) 'embedding': embedding,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      role: MessageRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'],
      imageBase64: json['imageBase64'],
      embedding: (json['embedding'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
