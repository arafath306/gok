import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class GetVerificationStatusUseCase {
  final IProfileRepository repository;

  GetVerificationStatusUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>?>> call() {
    return repository.fetchUserVerificationRequest();
  }
}
