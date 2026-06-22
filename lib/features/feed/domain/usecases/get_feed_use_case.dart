import '../../../../core/error/failures.dart';
import '../entities/thread_post_entity.dart';
import '../repositories/feed_repository.dart';

class GetFeedUseCase {
  final IFeedRepository repository;

  GetFeedUseCase(this.repository);

  Future<Either<Failure, List<ThreadPostEntity>>> call({bool silent = false}) {
    return repository.fetchFeed(silent: silent);
  }
}
