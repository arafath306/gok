import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class FetchVerificationPlansUseCase {
  final IProfileRepository repository;

  FetchVerificationPlansUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call() {
    return repository.fetchVerificationPlans();
  }
}
