import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  UserEntity? get currentUser {
    final sbUser = remoteDataSource.currentUser;
    return sbUser != null ? _mapToEntity(sbUser) : null;
  }

  @override
  Stream<UserEntity?> get onAuthStateChanged {
    return remoteDataSource.onAuthStateChanged.map((authState) {
      final user = authState.session?.user;
      return user != null ? _mapToEntity(user) : null;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final sbUser = await remoteDataSource.login(email, password);
      return Right(_mapToEntity(sbUser));
    } catch (e) {
      final cleanMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      return Left(ServerFailure(cleanMessage));
    }
  }

  @override
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
  }) async {
    try {
      final result = await remoteDataSource.signup(
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
      return Right(result);
    } catch (e) {
      final cleanMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      return Left(ServerFailure(cleanMessage));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  UserEntity _mapToEntity(sb.User user) {
    final metadata = user.userMetadata ?? {};
    final email = user.email ?? '';
    return UserEntity(
      id: user.id,
      email: email,
      fullName: (metadata['full_name'] as String?) ?? email.split('@')[0],
      username: (metadata['username'] as String?) ?? email.split('@')[0],
      phone: (metadata['phone'] as String?),
      birthdate: (metadata['birthdate'] as String?),
    );
  }
}
