import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:doc_text_extractor/doc_text_extractor.dart';
import '../../models/message.dart';
import '../../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/service_selector.dart';
import 'chat_history_screen.dart';

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
              ref
                  .read(activeChatSessionProvider.notifier)
                  .createNewSession(serviceType);
            },
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              );
            },
            tooltip: 'Chat History',
          ),
          const ServiceSelector(),
        ],
      ),
      body: activeSession == null
          ? const Center(child: Text('No active chat session'))
          : Column(
              children: [
                Expanded(child: MessageList(messages: activeSession.messages)),
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
  File? _selectedImage;
  File? _selectedPdf;

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
      _canSend =
          text.isNotEmpty || _selectedImage != null || _selectedPdf != null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _updateCanSend();
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
        _updateCanSend();
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null && _selectedPdf == null) return;

    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      await ref
          .read(activeChatSessionProvider.notifier)
          .sendMessageWithImage(text, base64Image);
    } else if (_selectedPdf != null) {
      final extractor = TextExtractor();
      final result = await extractor.extractText(
        _selectedPdf!.path,
        isUrl: false,
      );
      final pdfText = result.text;
      final displayText =
          text.isNotEmpty ? text : 'Summarize PDF: ${result.filename}';
      await ref
          .read(activeChatSessionProvider.notifier)
          .sendMessageWithPdf(displayText, pdfText);
    } else {
      await ref.read(activeChatSessionProvider.notifier).sendMessage(text);
    }

    _controller.clear();
    setState(() {
      _selectedImage = null;
      _selectedPdf = null;
      _updateCanSend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final activeSession = ref.watch(activeChatSessionProvider);
    final isConfigured = ref.watch(selectedLlmServiceProvider).isConfigured();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      _selectedImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                        _updateCanSend();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedPdf != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 24),
                        const SizedBox(width: 8),
                        Text(_selectedPdf!.path.split('/').last),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPdf = null;
                        _updateCanSend();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
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
              IconButton(
                icon: Icon(
                  _selectedImage == null ? Icons.attach_file : Icons.check,
                ),
                onPressed: isLoading ? null : _pickImage,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8.0),
              IconButton(
                icon: Icon(
                  _selectedPdf == null ? Icons.picture_as_pdf : Icons.check,
                ),
                onPressed: isLoading ? null : _pickPdf,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8.0),
              FutureBuilder<bool>(
                future: isConfigured,
                builder: (context, snapshot) {
                  final isReady = snapshot.data ?? false;

                  return IconButton(
                    icon: const Icon(Icons.send),
                    onPressed:
                        _canSend &&
                            !isLoading &&
                            activeSession != null &&
                            isReady
                        ? _sendMessage
                        : null,
                    color: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
