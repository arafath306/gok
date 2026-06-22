import '../../../../core/error/failures.dart';
import '../repositories/feed_repository.dart';

class FetchCommentsUseCase {
  final IFeedRepository repository;

  FetchCommentsUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call(String threadId) {
    return repository.fetchComments(threadId);
  }
}
