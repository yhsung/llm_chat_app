import '../models/chat_session.dart';
import 'llm_service.dart';
import 'openai_service.dart';
import 'azure_openai_service.dart';
import 'ollama_service.dart';

class LlmServiceFactory {
  // Singleton instance
  static final LlmServiceFactory _instance = LlmServiceFactory._internal();
  
  // Private constructor
  LlmServiceFactory._internal();
  
  // Factory constructor
  factory LlmServiceFactory() {
    return _instance;
  }
  
  // Cached instances of services
  final OpenAiService _openAiService = OpenAiService();
  final AzureOpenAiService _azureOpenAiService = AzureOpenAiService();
  final OllamaService _ollamaService = OllamaService();
  
  // Get service by type
  LlmService getService(LlmServiceType serviceType) {
    switch (serviceType) {
      case LlmServiceType.openAi:
        return _openAiService;
      case LlmServiceType.azureOpenAi:
        return _azureOpenAiService;
      case LlmServiceType.ollama:
        return _ollamaService;
    }
  }
  
  // Get all available services
  List<LlmService> getAllServices() {
    return [
      _openAiService,
      _azureOpenAiService,
      _ollamaService,
    ];
  }
  
  // Get OpenAI service
  OpenAiService get openAiService => _openAiService;
  
  // Get Azure OpenAI service
  AzureOpenAiService get azureOpenAiService => _azureOpenAiService;
  
  // Get Ollama service
  OllamaService get ollamaService => _ollamaService;
}