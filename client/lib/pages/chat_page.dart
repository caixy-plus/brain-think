import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_provider.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scrollCtrl = ScrollController();

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

  String _currentTitle(WidgetRef ref) {
    final conv = ref.watch(conversationListProvider);
    if (conv.currentId == null) return '头脑风暴';
    for (final c in conv.items) {
      if (c.id == conv.currentId) return c.title;
    }
    return '头脑风暴';
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final auth = ref.watch(authProvider);
    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    final cs = Theme.of(context).colorScheme;
    final title = _currentTitle(ref);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      drawer: const ChatHistoryDrawer(),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: '历史对话',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('头脑风暴',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '新会话',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: auth.loggedIn
                ? () => ref.read(conversationListProvider.notifier).createNew()
                : () => context.push('/login'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: chat.loading
                  ? const Center(child: CircularProgressIndicator())
                  : chat.messages.isEmpty
                      ? _EmptyHint(cs: cs)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: chat.messages.length,
                          itemBuilder: (_, i) =>
                              MessageBubble(message: chat.messages[i]),
                        ),
            ),
            if (auth.loggedIn)
              ChatInput(
                sending: chat.sending,
                onSend: (text) => ref.read(chatProvider.notifier).send(text),
              )
            else
              _LoginBar(onLogin: () => context.push('/login')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }
}

class _LoginBar extends StatelessWidget {
  const _LoginBar({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '登录后即可开始头脑风暴',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
            ),
            FilledButton.icon(
              key: const Key('chatLoginButton'),
              onPressed: onLogin,
              icon: const Icon(Icons.login, size: 18),
              label: const Text('去登录'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [cs.primary, cs.tertiary],
                ),
              ),
              child: const Icon(Icons.psychology_alt_outlined,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('开始一段头脑风暴',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 6),
            Text('在下方输入你想聊的内容，或左边切换历史对话',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
