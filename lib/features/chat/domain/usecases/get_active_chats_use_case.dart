import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class GetActiveChatsUseCase {
  final IChatRepository repository;

  GetActiveChatsUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call() {
    return repository.fetchActiveChats();
  }
}
