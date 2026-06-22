import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SignupUseCase {
  final IAuthRepository repository;

  const SignupUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required String birthdate,
    String? username,
    String? division,
    String? city,
    String? village,
    String? zip,
  }) {
    return repository.signup(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      gender: gender,
      birthdate: birthdate,
      username: username,
      division: division,
      city: city,
      village: village,
      zip: zip,
    );
  }
}
