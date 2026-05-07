import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/chat_api.dart';
import '../models/conversation.dart';
import 'auth_provider.dart';

class ConversationListState {
  const ConversationListState({
    this.items = const [],
    this.currentId,
    this.loading = false,
    this.error,
  });

  final List<Conversation> items;
  final int? currentId;
  final bool loading;
  final String? error;

  ConversationListState copyWith({
    List<Conversation>? items,
    int? currentId,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearCurrent = false,
  }) =>
      ConversationListState(
        items: items ?? this.items,
        currentId: clearCurrent ? null : (currentId ?? this.currentId),
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ConversationListController extends StateNotifier<ConversationListState> {
  ConversationListController(this._ref) : super(const ConversationListState()) {
    // 等到登录后再加载
    _ref.listen(authProvider, (prev, next) {
      if (!(prev?.loggedIn ?? false) && next.loggedIn) {
        refresh(autoCreateIfEmpty: true);
      }
      if ((prev?.loggedIn ?? false) && !next.loggedIn) {
        state = const ConversationListState();
      }
    }, fireImmediately: true);
    if (_ref.read(authProvider).loggedIn) {
      refresh(autoCreateIfEmpty: true);
    }
  }

  final Ref _ref;

  Future<void> refresh({bool autoCreateIfEmpty = false}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final list = await _ref.read(chatApiProvider).listConversations();
      int? curr = state.currentId;
      // 当前选中的还在列表里就保留；否则用最新的；空列表按需新建
      if (list.isEmpty) {
        if (autoCreateIfEmpty) {
          final created = await _ref.read(chatApiProvider).createConversation();
          state = state.copyWith(items: [created], currentId: created.id, loading: false);
          return;
        }
        state = state.copyWith(items: const [], loading: false, clearCurrent: true);
        return;
      }
      if (curr == null || !list.any((c) => c.id == curr)) {
        curr = list.first.id;
      }
      state = state.copyWith(items: list, currentId: curr, loading: false);
    } catch (e) {
      debugPrint('[BT-CONV] refresh 失败：$e');
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> createNew() async {
    try {
      final created = await _ref.read(chatApiProvider).createConversation();
      final next = [created, ...state.items];
      state = state.copyWith(items: next, currentId: created.id, clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void select(int id) {
    if (state.currentId == id) return;
    state = state.copyWith(currentId: id);
  }

  Future<void> remove(int id) async {
    try {
      await _ref.read(chatApiProvider).deleteConversation(id);
      final next = state.items.where((c) => c.id != id).toList();
      int? curr = state.currentId;
      if (curr == id) {
        curr = next.isNotEmpty ? next.first.id : null;
      }
      state = state.copyWith(items: next, currentId: curr, clearCurrent: curr == null);
      if (next.isEmpty) {
        // 删光了就再起一条空会话，避免空状态
        await createNew();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 服务端在 send 时可能创建/更新会话（自动重命名等），
  /// 客户端发完之后调用这个把列表+当前 id 同步过来。
  Future<void> syncAfterSend(int conversationId) async {
    try {
      final list = await _ref.read(chatApiProvider).listConversations();
      state = state.copyWith(items: list, currentId: conversationId, clearError: true);
    } catch (e) {
      debugPrint('[BT-CONV] syncAfterSend 失败：$e');
    }
  }
}

final conversationListProvider =
    StateNotifierProvider<ConversationListController, ConversationListState>(
        (ref) => ConversationListController(ref));
