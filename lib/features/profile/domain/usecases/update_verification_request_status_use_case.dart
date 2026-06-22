import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class UpdateVerificationRequestStatusUseCase {
  final IProfileRepository repository;

  UpdateVerificationRequestStatusUseCase(this.repository);

  Future<Either<Failure, bool>> call(String requestId, String status, {String? reason}) {
    return repository.updateVerificationRequestStatus(requestId, status, reason: reason);
  }
}
