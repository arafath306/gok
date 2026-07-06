import '../../../../core/error/failures.dart';
import '../repositories/feed_repository.dart';

class CreateThreadUseCase {
  final IFeedRepository repository;

  CreateThreadUseCase(this.repository);

  Future<Either<Failure, bool>> call(
    String content, {
    List<String>? imageUrls,
    String? videoUrl,
    String? audience,
    List<String>? pollOptions,
    DateTime? pollExpiresAt,
    String? communityId,
  }) {
    return repository.createThread(
      content,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      audience: audience,
      pollOptions: pollOptions,
      pollExpiresAt: pollExpiresAt,
      communityId: communityId,
    );
  }
}
