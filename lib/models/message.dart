import 'package:uuid/uuid.dart';

enum MessageRole {
  user,
  assistant,
  system,
}

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

  Message({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Message copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.toString().split('.').last,
      'content': content,
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
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}