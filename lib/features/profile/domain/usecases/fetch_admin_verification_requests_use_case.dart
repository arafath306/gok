import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class FetchAdminVerificationRequestsUseCase {
  final IProfileRepository repository;

  FetchAdminVerificationRequestsUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call() {
    return repository.fetchAdminVerificationRequests();
  }
}
