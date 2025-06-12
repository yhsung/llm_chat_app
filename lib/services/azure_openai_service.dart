import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message.dart';
import 'llm_service.dart';

class AzureOpenAiService implements LlmService {
  static const String _apiKeyKey = 'azure_openai_api_key';
  static const String _endpointKey = 'azure_openai_endpoint';
  static const String _deploymentKey = 'azure_openai_deployment';
  static const String _apiVersionKey = 'azure_openai_api_version';
  static const String _defaultDeployment = 'gpt-35-turbo';
  static const String _defaultApiVersion = '2023-05-15';
  
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  @override
  String get serviceName => 'Azure OpenAI';
  
  @override
  Future<bool> isConfigured() async {
    final apiKey = await _secureStorage.read(key: _apiKeyKey);
    final endpoint = await _secureStorage.read(key: _endpointKey);
    return apiKey != null && apiKey.isNotEmpty && 
           endpoint != null && endpoint.isNotEmpty;
  }
  
  @override
  Future<Message> sendMessage(List<Message> messages) async {
    final apiKey = await _secureStorage.read(key: _apiKeyKey);
    final endpoint = await _secureStorage.read(key: _endpointKey);
    final deployment = await getCurrentModel();
    final apiVersion = await _secureStorage.read(key: _apiVersionKey) ?? _defaultApiVersion;
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Azure OpenAI API key not configured');
    }
    
    if (endpoint == null || endpoint.isEmpty) {
      throw Exception('Azure OpenAI endpoint not configured');
    }
    
    final formattedMessages = messages.map((m) => {
      'role': m.role.toString().split('.').last,
      'content': m.content,
    }).toList();
    
    final url = '$endpoint/openai/deployments/$deployment/chat/completions?api-version=$apiVersion';
    
    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'messages': formattedMessages,
        },
      );
      
      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return Message(
          role: MessageRole.assistant,
          content: content,
        );
      } else {
        throw Exception('Failed to get response from Azure OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error communicating with Azure OpenAI: $e');
    }
  }
  
  @override
  Future<List<String>> getAvailableModels() async {
    // In Azure OpenAI, models are deployments that you create in your Azure portal
    // This is a placeholder - in a real app, you might want to fetch the actual deployments
    return [
      'gpt-35-turbo',
      'gpt-4',
      'gpt-4-32k',
    ];
  }
  
  @override
  Future<void> setModel(String model) async {
    await _secureStorage.write(key: _deploymentKey, value: model);
  }
  
  @override
  Future<String> getCurrentModel() async {
    return await _secureStorage.read(key: _deploymentKey) ?? _defaultDeployment;
  }
  
  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }
  
  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }
  
  Future<void> setEndpoint(String endpoint) async {
    await _secureStorage.write(key: _endpointKey, value: endpoint);
  }
  
  Future<String?> getEndpoint() async {
    return await _secureStorage.read(key: _endpointKey);
  }
  
  Future<void> setApiVersion(String apiVersion) async {
    await _secureStorage.write(key: _apiVersionKey, value: apiVersion);
  }
  
  Future<String> getApiVersion() async {
    return await _secureStorage.read(key: _apiVersionKey) ?? _defaultApiVersion;
  }
}