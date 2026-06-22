import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final IChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(String receiverId, String content, {String? mediaUrl, String? mediaType}) {
    return repository.sendMessage(receiverId, content, mediaUrl: mediaUrl, mediaType: mediaType);
  }
}
