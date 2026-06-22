import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SignOutUseCase {
  final IAuthRepository repository;

  const SignOutUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.signOut();
  }
}
