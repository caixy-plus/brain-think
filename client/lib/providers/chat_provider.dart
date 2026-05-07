import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/chat_api.dart';
import '../models/chat_message.dart';
import 'conversation_provider.dart';

class ChatState {
  const ChatState({
    this.conversationId,
    this.messages = const [],
    this.sending = false,
    this.loading = false,
    this.error,
  });

  final int? conversationId;
  final List<ChatMessage> messages;
  final bool sending;
  final bool loading;
  final String? error;

  ChatState copyWith({
    int? conversationId,
    List<ChatMessage>? messages,
    bool? sending,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearConversation = false,
  }) =>
      ChatState(
        conversationId: clearConversation ? null : (conversationId ?? this.conversationId),
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._ref) : super(const ChatState()) {
    // 跟随 conversationListProvider.currentId 切换
    _ref.listen<ConversationListState>(conversationListProvider, (prev, next) {
      if (prev?.currentId != next.currentId) {
        if (next.currentId == null) {
          state = const ChatState();
        } else {
          loadFor(next.currentId!);
        }
      }
    }, fireImmediately: true);
  }

  final Ref _ref;

  Future<void> loadFor(int conversationId) async {
    state = state.copyWith(
      conversationId: conversationId,
      messages: const [],
      loading: true,
      clearError: true,
    );
    try {
      final list = await _ref.read(chatApiProvider).loadMessages(conversationId);
      // 切换中可能又被切到别处，丢弃旧请求结果
      if (state.conversationId != conversationId) return;
      state = state.copyWith(messages: list, loading: false);
    } catch (e) {
      debugPrint('[BT-CHAT] loadFor 失败：$e');
      if (state.conversationId != conversationId) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    final convId = state.conversationId;
    final user = ChatMessage(role: ChatRole.user, content: trimmed);
    final placeholder = ChatMessage(role: ChatRole.assistant, content: '...', pending: true);
    state = state.copyWith(
      messages: [...state.messages, user, placeholder],
      sending: true,
      clearError: true,
    );
    try {
      final result = await _ref.read(chatApiProvider).send(trimmed, conversationId: convId);
      final updated = [...state.messages];
      updated[updated.length - 1] = ChatMessage(
        role: ChatRole.assistant,
        content: result.reply,
        model: result.model,
      );
      state = state.copyWith(
        messages: updated,
        sending: false,
        conversationId: result.conversationId,
      );
      // 第一条消息会让服务端把会话标题从「新会话」改成正文摘要，
      // 拉一次列表回来同步，并把当前 id 锁到服务端真正用到的那条
      _ref.read(conversationListProvider.notifier).syncAfterSend(result.conversationId);
    } catch (e) {
      final updated = [...state.messages];
      updated[updated.length - 1] = ChatMessage(
        role: ChatRole.assistant,
        content: '出错：$e',
      );
      state = state.copyWith(messages: updated, sending: false, error: e.toString());
    }
  }
}

final chatProvider = StateNotifierProvider<ChatController, ChatState>(
    (ref) => ChatController(ref));
