import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class UpdateVerificationPlanPriceUseCase {
  final IProfileRepository repository;

  UpdateVerificationPlanPriceUseCase(this.repository);

  Future<Either<Failure, bool>> call(String planId, double price, {double? discountPrice}) {
    return repository.updateVerificationPlanPrice(planId, price, discountPrice: discountPrice);
  }
}
