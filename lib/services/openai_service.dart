import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message.dart';
import 'llm_service.dart';

class OpenAiService implements LlmService {
  static const String _apiKeyKey = 'openai_api_key';
  static const String _modelKey = 'openai_model';
  static const String _defaultModel = 'gpt-3.5-turbo';
  static const String _baseUrl = 'https://api.openai.com/v1';

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  String get serviceName => 'OpenAI';

  @override
  Future<bool> isConfigured() async {
    final apiKey = await _secureStorage.read(key: _apiKeyKey);
    return apiKey != null && apiKey.isNotEmpty;
  }

  @override
  Future<Message> sendMessage(List<Message> messages) async {
    final apiKey = await _secureStorage.read(key: _apiKeyKey);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    final model = await getCurrentModel();

    final formattedMessages = messages
        .map(
          (m) => {
            'role': m.role.toString().split('.').last,
            'content': m.content,
          },
        )
        .toList();

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {'model': model, 'messages': formattedMessages},
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return Message(role: MessageRole.assistant, content: content);
      } else {
        throw Exception(
          'Failed to get response from OpenAI: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error communicating with OpenAI: $e');
    }
  }

  @override
  Future<Message> sendMessageWithImage(
    List<Message> messages,
    String base64Image,
  ) async {
    final apiKey = await _secureStorage.read(key: _apiKeyKey);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    final model = await getCurrentModel();

    final formattedMessages = messages.map((m) {
      final role = m.role.toString().split('.').last;
      if (identical(m, messages.last) && m.role == MessageRole.user) {
        return {
          'role': role,
          'content': [
            {'type': 'text', 'text': m.content},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/png;base64,$base64Image'},
            },
          ],
        };
      }
      return {'role': role, 'content': m.content};
    }).toList();

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {'model': model, 'messages': formattedMessages},
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return Message(role: MessageRole.assistant, content: content);
      } else {
        throw Exception(
          'Failed to get response from OpenAI: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error communicating with OpenAI: $e');
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    return ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo'];
  }

  @override
  Future<void> setModel(String model) async {
    await _secureStorage.write(key: _modelKey, value: model);
  }

  @override
  Future<String> getCurrentModel() async {
    return await _secureStorage.read(key: _modelKey) ?? _defaultModel;
  }

  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }
}
