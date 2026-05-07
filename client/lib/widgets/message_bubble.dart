import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.role == ChatRole.user;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: EdgeInsets.fromLTRB(isUser ? 48 : 12, 6, isUser ? 12 : 48, 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _AssistantAvatar(cs: cs),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78),
                  child: _BubbleBox(
                    isUser: isUser,
                    pending: message.pending,
                    content: message.content,
                  ),
                ),
              ),
            ],
          ),
          if (message.createdAt != null && !message.pending)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isUser ? 0 : 36, 4, isUser ? 4 : 0, 0),
              child: Text(
                DateFormat('HH:mm').format(message.createdAt!.toLocal()),
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.tertiary],
        ),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
    );
  }
}

class _BubbleBox extends StatelessWidget {
  const _BubbleBox({
    required this.isUser,
    required this.pending,
    required this.content,
  });

  final bool isUser;
  final bool pending;
  final String content;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );

    final boxDecoration = isUser
        ? BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.primary, cs.tertiary],
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          )
        : BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: radius,
            border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
          );

    final fg = isUser ? Colors.white : cs.onSurface;

    return Container(
      decoration: boxDecoration,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: pending
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: fg.withOpacity(0.7)),
                const SizedBox(width: 4),
                _Dot(color: fg.withOpacity(0.5)),
                const SizedBox(width: 4),
                _Dot(color: fg.withOpacity(0.35)),
              ],
            )
          : SelectableText(
              content,
              style: TextStyle(color: fg, fontSize: 15, height: 1.45),
            ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ac,
      child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
