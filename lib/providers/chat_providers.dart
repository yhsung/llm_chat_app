import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_session.dart';
import '../models/message.dart';
import '../services/llm_service.dart';
import '../services/llm_service_factory.dart';

// Provider for the LLM service factory
final llmServiceFactoryProvider = Provider<LlmServiceFactory>((ref) {
  return LlmServiceFactory();
});

// Provider for the currently selected LLM service type
final selectedServiceTypeProvider = StateProvider<LlmServiceType>((ref) {
  return LlmServiceType.openAi;
});

// Provider for the currently selected LLM service
final selectedLlmServiceProvider = Provider<LlmService>((ref) {
  final serviceType = ref.watch(selectedServiceTypeProvider);
  final factory = ref.watch(llmServiceFactoryProvider);
  return factory.getService(serviceType);
});

// Provider for the list of chat sessions
final chatSessionsProvider = StateNotifierProvider<ChatSessionsNotifier, List<ChatSession>>((ref) {
  return ChatSessionsNotifier();
});

// Provider for the currently active chat session
final activeChatSessionProvider = StateNotifierProvider<ActiveChatSessionNotifier, ChatSession?>((ref) {
  return ActiveChatSessionNotifier(ref);
});

// Provider for the loading state
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Notifier for managing the list of chat sessions
class ChatSessionsNotifier extends StateNotifier<List<ChatSession>> {
  ChatSessionsNotifier() : super([]);
  
  void addSession(ChatSession session) {
    state = [...state, session];
  }
  
  void updateSession(ChatSession updatedSession) {
    state = [
      for (final session in state)
        if (session.id == updatedSession.id) updatedSession else session,
    ];
  }
  
  void deleteSession(String sessionId) {
    state = state.where((session) => session.id != sessionId).toList();
  }
  
  ChatSession? getSessionById(String id) {
    try {
      return state.firstWhere((session) => session.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Notifier for managing the active chat session
class ActiveChatSessionNotifier extends StateNotifier<ChatSession?> {
  final Ref _ref;
  
  ActiveChatSessionNotifier(this._ref) : super(null);
  
  void setActiveSession(ChatSession session) {
    state = session;
  }
  
  void createNewSession(LlmServiceType serviceType) {
    final newSession = ChatSession(
      serviceType: serviceType,
      title: 'New Chat',
    );
    
    // Add to the list of sessions
    _ref.read(chatSessionsProvider.notifier).addSession(newSession);
    
    // Set as active session
    state = newSession;
  }
  
  Future<void> sendMessage(String content) async {
    if (state == null) return;
    
    // Create user message
    final userMessage = Message(
      role: MessageRole.user,
      content: content,
    );
    
    // Add user message to the session
    final updatedSession = state!.addMessage(userMessage);
    state = updatedSession;
    _ref.read(chatSessionsProvider.notifier).updateSession(updatedSession);
    
    // Set loading state
    _ref.read(isLoadingProvider.notifier).state = true;
    
    try {
      // Get the selected LLM service
      final llmService = _ref.read(selectedLlmServiceProvider);
      
      // Send the message to the LLM service
      final assistantMessage = await llmService.sendMessage(updatedSession.messages);
      
      // Add the assistant's response to the session
      final finalSession = updatedSession.addMessage(assistantMessage);
      state = finalSession;
      _ref.read(chatSessionsProvider.notifier).updateSession(finalSession);
    } catch (e) {
      // Add error message
      final errorMessage = Message(
        role: MessageRole.assistant,
        content: 'Error: ${e.toString()}',
      );
      
      final finalSession = updatedSession.addMessage(errorMessage);
      state = finalSession;
      _ref.read(chatSessionsProvider.notifier).updateSession(finalSession);
    } finally {
      // Reset loading state
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }
}