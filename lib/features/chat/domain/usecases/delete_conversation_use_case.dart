import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class DeleteConversationUseCase {
  final IChatRepository repository;

  DeleteConversationUseCase(this.repository);

  Future<Either<Failure, bool>> call(String otherUserId) {
    return repository.deleteConversation(otherUserId);
  }
}
