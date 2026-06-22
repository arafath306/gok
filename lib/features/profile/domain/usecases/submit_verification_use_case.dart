import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class SubmitVerificationUseCase {
  final IProfileRepository repository;

  SubmitVerificationUseCase(this.repository);

  Future<Either<Failure, bool>> call(Map<String, dynamic> requestData) {
    return repository.submitVerificationRequest(requestData);
  }
}
