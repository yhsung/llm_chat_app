import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/message.dart';
import '../../models/chat_session.dart';
import '../../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/service_selector.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeChatSessionProvider);
    final isLoading = ref.watch(isLoadingProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(activeSession?.title ?? 'New Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final serviceType = ref.read(selectedServiceTypeProvider);
              ref.read(activeChatSessionProvider.notifier).createNewSession(serviceType);
            },
            tooltip: 'New Chat',
          ),
          const ServiceSelector(),
        ],
      ),
      body: activeSession == null
          ? const Center(child: Text('No active chat session'))
          : Column(
              children: [
                Expanded(
                  child: MessageList(messages: activeSession.messages),
                ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  ),
                const MessageInput(),
              ],
            ),
    );
  }
}

class MessageList extends StatelessWidget {
  final List<Message> messages;

  const MessageList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      reverse: false,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(message: message);
      },
    );
  }
}

class MessageInput extends ConsumerStatefulWidget {
  const MessageInput({super.key});

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateCanSend);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCanSend);
    _controller.dispose();
    super.dispose();
  }

  void _updateCanSend() {
    final text = _controller.text.trim();
    setState(() {
      _canSend = text.isNotEmpty;
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(activeChatSessionProvider.notifier).sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final activeSession = ref.watch(activeChatSessionProvider);
    final isConfigured = ref.watch(selectedLlmServiceProvider).isConfigured();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (_canSend && !isLoading && activeSession != null) {
                  _sendMessage();
                }
              },
              enabled: !isLoading && activeSession != null,
            ),
          ),
          const SizedBox(width: 8.0),
          FutureBuilder<bool>(
            future: isConfigured,
            builder: (context, snapshot) {
              final isReady = snapshot.data ?? false;
              
              return IconButton(
                icon: const Icon(Icons.send),
                onPressed: _canSend && !isLoading && activeSession != null && isReady
                    ? _sendMessage
                    : null,
                color: Theme.of(context).colorScheme.primary,
              );
            },
          ),
        ],
      ),
    );
  }
}