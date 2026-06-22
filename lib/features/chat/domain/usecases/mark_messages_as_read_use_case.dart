import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class MarkMessagesAsReadUseCase {
  final IChatRepository repository;

  MarkMessagesAsReadUseCase(this.repository);

  Future<Either<Failure, void>> call(String otherUserId) {
    return repository.markMessagesAsRead(otherUserId);
  }
}
