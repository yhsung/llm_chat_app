import '../models/message.dart';

abstract class LlmService {
  /// The name of the service
  String get serviceName;
  
  /// Whether the service is configured with valid API keys
  Future<bool> isConfigured();
  
  /// Send a message to the LLM service and get a response
  Future<Message> sendMessage(List<Message> messages);

  /// Send a message with an attached image encoded as base64
  Future<Message> sendMessageWithImage(
    List<Message> messages,
    String base64Image,
  );

  /// Generate an embedding vector for the provided text
  Future<List<double>> embedText(String text);
  
  /// Get the available models for this service
  Future<List<String>> getAvailableModels();
  
  /// Set the model to use for this service
  Future<void> setModel(String model);
  
  /// Get the current model being used
  Future<String> getCurrentModel();
}