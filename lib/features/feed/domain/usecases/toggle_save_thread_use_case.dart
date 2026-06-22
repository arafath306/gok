import '../../../../core/error/failures.dart';
import '../repositories/feed_repository.dart';

class ToggleSaveThreadUseCase {
  final IFeedRepository repository;

  ToggleSaveThreadUseCase(this.repository);

  Future<Either<Failure, void>> call(String threadId, bool wasAlreadySaved) {
    return repository.toggleSaveThread(threadId, wasAlreadySaved);
  }
}
