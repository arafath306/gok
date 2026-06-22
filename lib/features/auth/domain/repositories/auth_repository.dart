import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  
  Future<Either<Failure, bool>> signup({
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
  });

  Future<Either<Failure, void>> signOut();

  UserEntity? get currentUser;
  Stream<UserEntity?> get onAuthStateChanged;
}
