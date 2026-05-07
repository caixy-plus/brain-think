import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/conversation.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';

class ChatHistoryDrawer extends ConsumerWidget {
  const ChatHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(conversationListProvider);
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Drawer(
      width: 320,
      backgroundColor: cs.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _UserHeader(
              isLoggedIn: auth.loggedIn,
              nickname: auth.user?.nickname ?? '未登录',
              email: auth.user?.email ?? '',
              avatarLetter: auth.user?.avatarLetter ?? '?',
              onLogin: () {
                Navigator.of(context).maybePop();
                context.push('/login');
              },
              onLogout: () async {
                Navigator.of(context).maybePop();
                await ref.read(authProvider.notifier).logout();
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Text('历史对话',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (list.loading)
                    const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    IconButton(
                      tooltip: '刷新',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: () =>
                          ref.read(conversationListProvider.notifier).refresh(),
                    ),
                ],
              ),
            ),
            Expanded(
              child: list.items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('还没有任何对话\n点右上角 + 开始一段',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: list.items.length,
                      itemBuilder: (_, i) {
                        final c = list.items[i];
                        final selected = list.currentId == c.id;
                        return _ConvTile(
                          conv: c,
                          selected: selected,
                          onTap: () {
                            ref.read(conversationListProvider.notifier).select(c.id);
                            Navigator.of(context).maybePop();
                          },
                          onDelete: () => _confirmDelete(context, ref, c),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text('brain-think · 头脑风暴',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Conversation c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定删除「${c.title}」？该会话内的全部消息都会被清掉。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(conversationListProvider.notifier).remove(c.id);
    }
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({
    required this.isLoggedIn,
    required this.nickname,
    required this.email,
    required this.avatarLetter,
    required this.onLogin,
    required this.onLogout,
  });

  final bool isLoggedIn;
  final String nickname;
  final String email;
  final String avatarLetter;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.tertiary],
        ),
      ),
      child: Row(
        children: [
          if (isLoggedIn)
            PopupMenuButton<String>(
              tooltip: '账号菜单',
              position: PopupMenuPosition.under,
              onSelected: (v) {
                if (v == 'logout') onLogout();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('退出登录', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.95),
                child: Text(
                  avatarLetter,
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            )
          else
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withOpacity(0.95),
              child: Icon(Icons.person_outline, color: cs.primary),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 12)),
                ] else if (!isLoggedIn) ...[
                  const SizedBox(height: 2),
                  Text('登录以同步历史对话',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 12)),
                ],
              ],
            ),
          ),
          if (isLoggedIn)
            IconButton(
              tooltip: '账号菜单',
              color: Colors.white,
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            )
          else
            TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('登录'),
            ),
        ],
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  const _ConvTile({
    required this.conv,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final Conversation conv;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('MM-dd HH:mm');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 18,
                    color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conv.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? cs.onPrimaryContainer : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fmt.format(conv.updatedAt.toLocal()),
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? cs.onPrimaryContainer.withOpacity(0.75)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: '删除',
                  icon: Icon(Icons.delete_outline,
                      size: 18,
                      color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
