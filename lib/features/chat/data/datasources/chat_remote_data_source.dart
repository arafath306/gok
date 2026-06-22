import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/security/e2ee_service.dart';

abstract class ChatRemoteDataSource {
  Future<List<dynamic>> fetchActiveChatsRaw(String currentUserId);
  Future<List<dynamic>> fetchMessagesRaw(String currentUserId, String otherUserId);
  Future<void> sendMessage(String senderId, String receiverId, String content, {String? mediaUrl, String? mediaType});
  Future<void> markMessagesAsRead(String currentUserId, String otherUserId);
  Future<bool> deleteConversation(String currentUserId, String otherUserId);
  Future<String?> uploadChatMedia(String currentUserId, Uint8List bytes);
  Stream<sb.PostgresChangePayload> getMessagesRealtimeStream(String otherUserId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final sb.SupabaseClient supabaseClient;
  final E2EEService e2eeService;

  ChatRemoteDataSourceImpl(this.supabaseClient, this.e2eeService);

  // Helper method to encrypt content before sending
  Future<String> _encryptContent(String content, String receiverId) async {
    if (content.isEmpty) return content;
    
    try {
      final receiverProfile = await supabaseClient.from('profiles').select('public_key').eq('id', receiverId).single();
      final receiverPublicKey = receiverProfile['public_key'] as String?;
      
      if (receiverPublicKey != null && receiverPublicKey.isNotEmpty) {
        final result = await e2eeService.encryptMessage(content, receiverPublicKey);
        if (result != null) {
          return 'E2EE:v1:${result.nonceBase64}:${result.macBase64}:${result.cipherTextBase64}';
        }
      }
    } catch (e) {
      print('Encryption failed: $e');
    }
    return content; // Fallback to plain text if encryption fails or receiver has no key
  }

  @override
  Future<List<dynamic>> fetchActiveChatsRaw(String currentUserId) async {
    final response = await supabaseClient
        .from('messages')
        .select('*, sender:profiles!sender_id(*), receiver:profiles!receiver_id(*)')
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .order('created_at', ascending: false);
    return response as List<dynamic>;
  }

  @override
  Future<List<dynamic>> fetchMessagesRaw(String currentUserId, String otherUserId) async {
    final response = await supabaseClient
        .from('messages')
        .select()
        .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)')
        .order('created_at', ascending: true);
    return response as List<dynamic>;
  }

  @override
  Future<void> sendMessage(String senderId, String receiverId, String content, {String? mediaUrl, String? mediaType}) async {
    final encryptedContent = await _encryptContent(content, receiverId);
    
    await supabaseClient.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': encryptedContent,
      'is_read': false,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaType != null) 'media_type': mediaType,
    });
  }

  @override
  Future<void> markMessagesAsRead(String currentUserId, String otherUserId) async {
    await supabaseClient
        .from('messages')
        .update({'is_read': true})
        .eq('sender_id', otherUserId)
        .eq('receiver_id', currentUserId)
        .eq('is_read', false);
  }

  @override
  Future<bool> deleteConversation(String currentUserId, String otherUserId) async {
    await supabaseClient
        .from('messages')
        .delete()
        .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)');
    return true;
  }

  @override
  Future<String?> uploadChatMedia(String currentUserId, Uint8List bytes) async {
    final path = 'chat_media/$currentUserId/chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabaseClient.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const sb.FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );
    final publicUrl = supabaseClient.storage.from('avatars').getPublicUrl(path);
    return publicUrl;
  }

  @override
  Stream<sb.PostgresChangePayload> getMessagesRealtimeStream(String otherUserId) {
    final channel = supabaseClient.channel('messages_realtime:$otherUserId');
    final controller = StreamController<sb.PostgresChangePayload>();
    
    final subscription = channel.onPostgresChanges(
      event: sb.PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        if (!controller.isClosed) {
          controller.add(payload);
        }
      },
    ).subscribe();

    controller.onCancel = () {
      supabaseClient.removeChannel(subscription);
      controller.close();
    };

    return controller.stream;
  }
}
