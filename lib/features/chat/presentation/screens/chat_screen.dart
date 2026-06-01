// lib/features/chat/presentation/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/data/auth_repository.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});
  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient().get('/chat');
      setState(() {
        _conversations = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Mensajes')),
      body: _loading
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5, separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, __) => SkeletonBox(width: double.infinity, height: 64, radius: 12),
            )
          : _conversations.isEmpty
              ? const EmptyState(title: 'Sin conversaciones', description: 'Contacta a un tutor desde el detalle de una asesoria')
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.ink,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final conv = _conversations[i];
                      final lastMsg = conv['last_message'] as Map<String, dynamic>?;
                      final name = lastMsg?['sender']?['full_name'] ?? 'Usuario';
                      final content = lastMsg?['content'] ?? '';
                      final convId = conv['conversation_id'] ?? '';
                      final unread = conv['unread_count'] ?? 0;

                      // Determine other user id from conversation_id
                      final parts = convId.split('_');
                      final otherId = parts.firstWhere(
                        (p) => p != (user?.id ?? '') && p.length > 10,
                        orElse: () => '',
                      );

                      return AppCard(
                        onTap: () => context.push('/chat/$convId?receiver_id=$otherId&receiver_name=${Uri.encodeComponent(name)}'),
                        child: Row(children: [
                          AppAvatar(name: name, size: 44),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(content, style: const TextStyle(fontSize: 12, color: AppColors.ink4),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                          if (unread > 0)
                            Container(
                              width: 20, height: 20,
                              decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                              child: Center(child: Text('$unread',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.ink))),
                            ),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String receiverId;
  final String receiverName;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient().get('/chat/${widget.conversationId}');
      setState(() {
        _messages = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending || widget.receiverId.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ApiClient().post('/chat/send', data: {
        'receiver_id': widget.receiverId,
        'content': text,
        'message_type': 'text',
      });
      _msgCtrl.clear();
      await _loadMessages();
    } catch (_) {} finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: Row(children: [
          AppAvatar(name: widget.receiverName, size: 32),
          const SizedBox(width: 10),
          Text(widget.receiverName, style: Theme.of(context).textTheme.titleMedium),
        ]),
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
              : _messages.isEmpty
                  ? const Center(child: Text('Escribe el primer mensaje', style: TextStyle(color: AppColors.ink4)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final mine = msg['sender']?['id'] == user?.id;
                        return _MessageBubble(
                          content: msg['content'] ?? '',
                          time: msg['created_at'] ?? '',
                          mine: mine,
                        );
                      },
                    ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.line, width: 1.5)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                maxLines: 4, minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  filled: true, fillColor: AppColors.bg2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface))
                    : const Icon(Icons.send_rounded, color: AppColors.surface, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final String time;
  final bool mine;

  const _MessageBubble({required this.content, required this.time, required this.mine});

  @override
  Widget build(BuildContext context) {
    String timeStr = '';
    try {
      final dt = DateTime.parse(time).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      timeStr = '$h:$m';
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
                border: mine ? null : Border.all(color: AppColors.line, width: 1.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(content, style: TextStyle(fontSize: 14, color: mine ? AppColors.surface : AppColors.ink, height: 1.4)),
                const SizedBox(height: 4),
                Text(timeStr, style: TextStyle(fontSize: 9, color: mine ? AppColors.surface.withOpacity(0.5) : AppColors.ink4)),
              ]),
            ),
          ),
          if (mine) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
