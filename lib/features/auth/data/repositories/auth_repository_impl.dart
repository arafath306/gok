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

  String _mapExceptionToMessage(Object e) {
    if (e is sb.AuthException) {
      final code = e.code;
      final message = e.message;
      
      if (code == 'email_address_invalid' || 
          message.contains('invalid email') || 
          message.contains('is invalid')) {
        return 'Please enter a valid email address.';
      }
      if (code == 'email_not_confirmed' || 
          message.contains('Email not confirmed')) {
        return 'Your email address has not been verified. Please check your inbox and verify your email before logging in.';
      }
      if (code == 'invalid_credentials' || 
          message.contains('Invalid login credentials')) {
        return 'Invalid email or password. Please try again.';
      }
      if (code == 'weak_password' || 
          message.contains('Password should be')) {
        return 'Password must be at least 6 characters long.';
      }
      if (message.contains('already registered') || 
          message.contains('already in use') || 
          message.contains('already exists')) {
        return 'An account with this email address already exists.';
      }
      return message;
    }
    
    final str = e.toString();
    if (str.contains('email_address_invalid') || str.contains('is invalid')) {
      return 'Please enter a valid email address.';
    }
    if (str.contains('email_not_confirmed')) {
      return 'Your email address has not been verified. Please check your inbox and verify your email before logging in.';
    }
    return str.replaceAll(RegExp(r'\[.*?\]'), '').trim();
  }

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final sbUser = await remoteDataSource.login(email, password);
      return Right(_mapToEntity(sbUser));
    } catch (e) {
      return Left(ServerFailure(_mapExceptionToMessage(e)));
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
      return Left(ServerFailure(_mapExceptionToMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(_mapExceptionToMessage(e)));
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
