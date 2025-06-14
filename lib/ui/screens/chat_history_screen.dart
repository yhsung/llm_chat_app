import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/chat_session.dart';
import '../../providers/chat_providers.dart';

class ChatHistoryScreen extends ConsumerWidget {
  const ChatHistoryScreen({super.key});

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, ChatSession session) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Chat'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Chat name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  ref
                      .read(chatSessionsProvider.notifier)
                      .renameSession(session.id, newName);
                  final updated = ref
                      .read(chatSessionsProvider.notifier)
                      .getSessionById(session.id);
                  final active = ref.read(activeChatSessionProvider);
                  if (updated != null && active?.id == session.id) {
                    ref
                        .read(activeChatSessionProvider.notifier)
                        .setActiveSession(updated);
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive) const Icon(Icons.check),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Rename',
                  onPressed: () => _showRenameDialog(context, ref, session),
                ),
              ],
            ),
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
