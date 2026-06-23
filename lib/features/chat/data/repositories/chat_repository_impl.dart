import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/error/failures.dart';
import '../../../../models/profile.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../../../../core/security/e2ee_service.dart';

class ChatRepositoryImpl implements IChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final sb.SupabaseClient supabaseClient;
  final E2EEService e2eeService;

  ChatRepositoryImpl(this.remoteDataSource, this.supabaseClient, this.e2eeService);

  String get _currentUid => supabaseClient.auth.currentUser?.id ?? '';

  final Map<String, String?> _publicKeyCache = {};

  Future<String> _decryptContent(String content, String senderPublicKey) async {
    if (content.startsWith('E2EE:v1:')) {
      final parts = content.split(':');
      if (parts.length == 5) {
        // format: E2EE : v1 : nonce : mac : ciphertext
        final nonceBase64 = parts[2];
        final macBase64 = parts[3];
        final cipherTextBase64 = parts[4];
        final decrypted = await e2eeService.decryptMessage(
          cipherTextBase64, 
          nonceBase64, 
          macBase64, 
          senderPublicKey,
        );
        return decrypted ?? '🔒 Decryption failed';
      }
    }
    return content;
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchActiveChats() async {
    try {
      final data = await remoteDataSource.fetchActiveChatsRaw(_currentUid);
      final Map<String, Map<String, dynamic>> conversations = {};

      for (final json in data) {
        final senderId = json['sender_id'] as String;
        final isMeSender = senderId == _currentUid;
        final otherUserMap = isMeSender ? json['receiver'] : json['sender'];
        
        if (otherUserMap == null) continue;
        final otherProfile = Profile.fromJson(otherUserMap as Map<String, dynamic>);
        final otherId = otherProfile.id;

        String content = json['content'] as String? ?? '';
        
        // Only decrypt the last message if we have the other user's public key
        if (content.startsWith('E2EE:v1:') && otherProfile.publicKey != null) {
            content = await _decryptContent(content, otherProfile.publicKey!);
        }

        if (content.startsWith('{') && content.endsWith('}') && content.contains('reply_to_id')) {
          try {
            final Map<String, dynamic> jsonReply = jsonDecode(content) as Map<String, dynamic>;
            content = jsonReply['text'] as String? ?? '';
          } catch (_) {}
        }

        final String mediaUrl = json['media_url'] as String? ?? '';
        final String displayMessage = content.isNotEmpty 
            ? content 
            : (mediaUrl.isNotEmpty ? '📷 Photo' : '');

        if (!conversations.containsKey(otherId)) {
          conversations[otherId] = {
            'profile': otherProfile,
            'lastMessage': displayMessage,
            'lastMessageTime': _getRelativeTime(DateTime.parse(json['created_at'] as String)),
            'unreadCount': (json['is_read'] == false && json['receiver_id'] == _currentUid) ? 1 : 0,
            'timeRaw': json['created_at'] as String,
          };
        } else {
          if (json['is_read'] == false && json['receiver_id'] == _currentUid) {
            conversations[otherId]!['unreadCount'] = (conversations[otherId]!['unreadCount'] as int) + 1;
          }
        }
      }

      return Right(conversations.values.toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String otherUserId) {
    final controller = StreamController<List<MessageEntity>>();

    Future<void> loadAndPush() async {
      try {
        // Get cached public key or fetch from Supabase
        String? otherPublicKey;
        if (_publicKeyCache.containsKey(otherUserId)) {
          otherPublicKey = _publicKeyCache[otherUserId];
        } else {
          final otherProfileRes = await supabaseClient.from('profiles').select('public_key').eq('id', otherUserId).single();
          otherPublicKey = otherProfileRes['public_key'] as String?;
          _publicKeyCache[otherUserId] = otherPublicKey;
        }

        final data = await remoteDataSource.fetchMessagesRaw(_currentUid, otherUserId);
        final List<MessageEntity> messages = [];

        for (final json in data) {
          String text = json['content'] as String? ?? '';
          final isMe = json['sender_id'] == _currentUid;
          
          if (text.startsWith('E2EE:v1:') && otherPublicKey != null) {
              text = await _decryptContent(text, otherPublicKey);
          }

          String? replyToId;
          String? replyToText;
          String? replyToSender;

          if (text.startsWith('{') && text.endsWith('}') && text.contains('reply_to_id')) {
            try {
              final Map<String, dynamic> jsonReply = jsonDecode(text) as Map<String, dynamic>;
              replyToId = jsonReply['reply_to_id'] as String?;
              replyToText = jsonReply['reply_to_text'] as String?;
              replyToSender = jsonReply['reply_to_sender'] as String?;
              text = jsonReply['text'] as String? ?? '';
            } catch (_) {}
          }

          messages.add(MessageEntity(
            id: json['id'] as String,
            text: text,
            isMe: isMe,
            time: _getRelativeTime(DateTime.parse(json['created_at'] as String)),
            createdAt: json['created_at'] as String,
            mediaUrl: json['media_url'] as String?,
            mediaType: json['media_type'] as String?,
            isRead: json['is_read'] as bool? ?? false,
            replyToId: replyToId,
            replyToText: replyToText,
            replyToSender: replyToSender,
          ));
        }
        
        if (!controller.isClosed) {
          controller.add(messages);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    }

    loadAndPush();

    final subscription = remoteDataSource.getMessagesRealtimeStream(otherUserId).listen((_) {
      loadAndPush();
    });

    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<Either<Failure, void>> sendMessage(String receiverId, String content, {String? mediaUrl, String? mediaType}) async {
    try {
      await remoteDataSource.sendMessage(_currentUid, receiverId, content, mediaUrl: mediaUrl, mediaType: mediaType);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead(String otherUserId) async {
    try {
      await remoteDataSource.markMessagesAsRead(_currentUid, otherUserId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteConversation(String otherUserId) async {
    try {
      final result = await remoteDataSource.deleteConversation(_currentUid, otherUserId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> uploadChatMedia(Uint8List bytes) async {
    try {
      final result = await remoteDataSource.uploadChatMedia(_currentUid, bytes);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> editMessage(String messageId, String receiverId, String newContent) async {
    try {
      await remoteDataSource.editMessage(messageId, _currentUid, receiverId, newContent);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      await remoteDataSource.deleteMessage(messageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _getRelativeTime(DateTime dt) {
    // Convert to Dhaka Time (GMT+6)
    final dhakaTime = dt.toUtc().add(const Duration(hours: 6));
    final nowDhaka = DateTime.now().toUtc().add(const Duration(hours: 6));

    final hour24 = dhakaTime.hour;
    final minute = dhakaTime.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final timeStr = '$hour12:$minute $period';

    final isToday = dhakaTime.year == nowDhaka.year &&
        dhakaTime.month == nowDhaka.month &&
        dhakaTime.day == nowDhaka.day;

    if (isToday) {
      return timeStr;
    } else {
      final day = dhakaTime.day.toString().padLeft(2, '0');
      final month = dhakaTime.month.toString().padLeft(2, '0');
      final year = dhakaTime.year;
      return '$day/$month/$year, $timeStr';
    }
  }
}
