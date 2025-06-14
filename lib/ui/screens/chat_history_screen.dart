import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/chat_session.dart';
import '../../providers/chat_providers.dart';

class ChatHistoryScreen extends ConsumerWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(chatSessionsProvider);
    final activeSession = ref.watch(activeChatSessionProvider);

    if (sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat History')),
        body: const Center(child: Text('No chat history')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chat History')),
      body: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final isActive = activeSession?.id == session.id;
          return ListTile(
            title: Text(session.title),
            subtitle: Text('Last updated: '
                '${DateFormat.yMd().add_jm().format(session.updatedAt)}'),
            trailing: isActive ? const Icon(Icons.check) : null,
            onTap: () {
              ref
                  .read(activeChatSessionProvider.notifier)
                  .setActiveSession(session);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
