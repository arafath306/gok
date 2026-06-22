import 'dart:typed_data';
import '../../../../core/error/failures.dart';
import '../entities/message_entity.dart';

abstract class IChatRepository {
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchActiveChats();
  Stream<List<MessageEntity>> getMessagesStream(String otherUserId);
  Future<Either<Failure, void>> sendMessage(String receiverId, String content, {String? mediaUrl, String? mediaType});
  Future<Either<Failure, void>> markMessagesAsRead(String otherUserId);
  Future<Either<Failure, bool>> deleteConversation(String otherUserId);
  Future<Either<Failure, String?>> uploadChatMedia(Uint8List bytes);
}
