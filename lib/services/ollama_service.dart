import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message.dart';
import 'llm_service.dart';

class OllamaService implements LlmService {
  static const String _endpointKey = 'ollama_endpoint';
  static const String _modelKey = 'ollama_model';
  static const String _defaultEndpoint = 'http://localhost:11434';
  static const String _defaultModel = 'llama2';

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  String get serviceName => 'Ollama';

  @override
  Future<bool> isConfigured() async {
    final endpoint = await _secureStorage.read(key: _endpointKey);
    return endpoint != null && endpoint.isNotEmpty;
  }

  @override
  Future<Message> sendMessage(List<Message> messages) async {
    final endpoint =
        await _secureStorage.read(key: _endpointKey) ?? _defaultEndpoint;
    final model = await getCurrentModel();

    // Format messages for Ollama
    // Ollama expects a simpler format than OpenAI
    final prompt = _formatMessagesForOllama(messages);

    try {
      final response = await _dio.post(
        '$endpoint/api/generate',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {'model': model, 'prompt': prompt, 'stream': false},
      );

      if (response.statusCode == 200) {
        final content = response.data['response'];
        return Message(role: MessageRole.assistant, content: content);
      } else {
        throw Exception(
          'Failed to get response from Ollama: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error communicating with Ollama: $e');
    }
  }

  @override
  Future<Message> sendMessageWithImage(
    List<Message> messages,
    String base64Image,
  ) async {
    // Ollama currently has no direct image input support; ignore the image.
    return sendMessage(messages);
  }

  String _formatMessagesForOllama(List<Message> messages) {
    // Simple formatting for Ollama
    // This is a basic implementation and might need to be adjusted based on the specific model
    final buffer = StringBuffer();

    for (final message in messages) {
      switch (message.role) {
        case MessageRole.system:
          buffer.writeln('System: ${message.content}');
          break;
        case MessageRole.user:
          buffer.writeln('User: ${message.content}');
          break;
        case MessageRole.assistant:
          buffer.writeln('Assistant: ${message.content}');
          break;
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  @override
  Future<List<String>> getAvailableModels() async {
    final endpoint =
        await _secureStorage.read(key: _endpointKey) ?? _defaultEndpoint;

    try {
      final response = await _dio.get('$endpoint/api/tags');

      if (response.statusCode == 200) {
        final models = (response.data['models'] as List)
            .map((model) => model['name'] as String)
            .toList();
        return models;
      } else {
        // Return default models if we can't fetch from server
        return ['llama2', 'mistral', 'gemma'];
      }
    } catch (e) {
      // Return default models if we can't fetch from server
      return ['llama2', 'mistral', 'gemma'];
    }
  }

  @override
  Future<void> setModel(String model) async {
    await _secureStorage.write(key: _modelKey, value: model);
  }

  @override
  Future<String> getCurrentModel() async {
    return await _secureStorage.read(key: _modelKey) ?? _defaultModel;
  }

  Future<void> setEndpoint(String endpoint) async {
    await _secureStorage.write(key: _endpointKey, value: endpoint);
  }

  Future<String> getEndpoint() async {
    return await _secureStorage.read(key: _endpointKey) ?? _defaultEndpoint;
  }
}
