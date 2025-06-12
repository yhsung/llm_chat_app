import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_session.dart';
import '../../providers/chat_providers.dart';

class ServiceSelector extends ConsumerWidget {
  const ServiceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServiceType = ref.watch(selectedServiceTypeProvider);
    
    return PopupMenuButton<LlmServiceType>(
      tooltip: 'Select LLM Service',
      icon: const Icon(Icons.swap_horiz),
      initialValue: selectedServiceType,
      onSelected: (LlmServiceType value) {
        ref.read(selectedServiceTypeProvider.notifier).state = value;
        
        // Create a new session with the selected service type
        ref.read(activeChatSessionProvider.notifier).createNewSession(value);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<LlmServiceType>>[
        const PopupMenuItem<LlmServiceType>(
          value: LlmServiceType.openAi,
          child: Row(
            children: [
              Icon(Icons.api),
              SizedBox(width: 8),
              Text('OpenAI'),
            ],
          ),
        ),
        const PopupMenuItem<LlmServiceType>(
          value: LlmServiceType.azureOpenAi,
          child: Row(
            children: [
              Icon(Icons.cloud),
              SizedBox(width: 8),
              Text('Azure OpenAI'),
            ],
          ),
        ),
        const PopupMenuItem<LlmServiceType>(
          value: LlmServiceType.ollama,
          child: Row(
            children: [
              Icon(Icons.computer),
              SizedBox(width: 8),
              Text('Ollama'),
            ],
          ),
        ),
      ],
    );
  }
}