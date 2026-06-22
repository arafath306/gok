import '../../../../core/error/failures.dart';
import '../repositories/feed_repository.dart';

class ToggleLikeUseCase {
  final IFeedRepository repository;

  ToggleLikeUseCase(this.repository);

  Future<Either<Failure, void>> call(String threadId, bool shouldLike) {
    return repository.toggleLike(threadId, shouldLike);
  }
}
