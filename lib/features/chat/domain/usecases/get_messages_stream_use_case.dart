import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class GetMessagesStreamUseCase {
  final IChatRepository repository;

  GetMessagesStreamUseCase(this.repository);

  Stream<List<MessageEntity>> call(String otherUserId) {
    return repository.getMessagesStream(otherUserId);
  }
}
