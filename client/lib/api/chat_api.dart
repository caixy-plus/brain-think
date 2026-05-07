import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import 'dio_client.dart';

final chatApiProvider = Provider<ChatApi>((ref) => ChatApi(ref.watch(dioProvider)));

class ChatApi {
  ChatApi(this._dio);
  final Dio _dio;

  /// POST /api/chat/send
  /// conversationId 不传则服务端自动取最新或新建
  Future<({String reply, String model, int conversationId})> send(
    String message, {
    int? conversationId,
    String? model,
  }) async {
    final res = await _dio.post('/chat/send', data: {
      'message': message,
      if (conversationId != null) 'conversationId': conversationId,
      if (model != null) 'model': model,
    });
    final body = res.data as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception(body['message'] ?? '发送失败');
    }
    final data = body['data'] as Map<String, dynamic>;
    return (
      reply: data['reply'] as String? ?? '',
      model: data['model'] as String? ?? '',
      conversationId: (data['conversationId'] as num?)?.toInt() ?? 0,
    );
  }

  /// GET /api/conversations
  Future<List<Conversation>> listConversations() async {
    final res = await _dio.get('/conversations');
    final body = res.data as Map<String, dynamic>;
    if (body['code'] != 0) return [];
    final list = (body['data'] as List<dynamic>? ?? []);
    return list.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/conversations
  Future<Conversation> createConversation() async {
    final res = await _dio.post('/conversations');
    final body = res.data as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception(body['message'] ?? '新建会话失败');
    }
    return Conversation.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// DELETE /api/conversations/{id}
  Future<void> deleteConversation(int id) async {
    final res = await _dio.delete('/conversations/$id');
    final body = res.data as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception(body['message'] ?? '删除会话失败');
    }
  }

  /// GET /api/conversations/{id}/messages
  Future<List<ChatMessage>> loadMessages(int conversationId) async {
    final res = await _dio.get('/conversations/$conversationId/messages');
    final body = res.data as Map<String, dynamic>;
    if (body['code'] != 0) return [];
    final list = (body['data'] as List<dynamic>? ?? []);
    return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }
}
