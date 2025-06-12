import 'package:uuid/uuid.dart';
import 'message.dart';

enum LlmServiceType {
  openAi,
  azureOpenAi,
  ollama,
}

extension LlmServiceTypeExtension on LlmServiceType {
  String get displayName {
    switch (this) {
      case LlmServiceType.openAi:
        return 'OpenAI';
      case LlmServiceType.azureOpenAi:
        return 'Azure OpenAI';
      case LlmServiceType.ollama:
        return 'Ollama';
    }
  }
}

class ChatSession {
  final String id;
  final String title;
  final List<Message> messages;
  final LlmServiceType serviceType;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    String? id,
    String? title,
    List<Message>? messages,
    required this.serviceType,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        title = title ?? 'New Chat',
        messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ChatSession copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    LlmServiceType? serviceType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      serviceType: serviceType ?? this.serviceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  ChatSession addMessage(Message message) {
    final updatedMessages = List<Message>.from(messages)..add(message);
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'serviceType': serviceType.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList(),
      serviceType: LlmServiceType.values.firstWhere(
        (e) => e.toString().split('.').last == json['serviceType'],
        orElse: () => LlmServiceType.openAi,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}