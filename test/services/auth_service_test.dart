import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:get_it/get_it.dart';
import 'package:dak/services/auth_service.dart';
import 'package:dak/core/error/failures.dart';
import 'package:dak/features/auth/domain/entities/user_entity.dart';
import 'package:dak/features/auth/domain/repositories/auth_repository.dart';
import 'package:dak/features/auth/domain/usecases/login_use_case.dart';
import 'package:dak/features/auth/domain/usecases/signup_use_case.dart';
import 'package:dak/features/auth/domain/usecases/sign_out_use_case.dart';

// Dummy implementation of IAuthRepository
class DummyAuthRepository implements IAuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock Usecases
class MockLoginUseCase extends LoginUseCase {
  MockLoginUseCase() : super(DummyAuthRepository());
  Either<Failure, UserEntity>? mockResult;

  @override
  Future<Either<Failure, UserEntity>> call(String email, String password) async {
    return mockResult ?? const Left(ServerFailure('Login failed'));
  }
}

class MockSignupUseCase extends SignupUseCase {
  MockSignupUseCase() : super(DummyAuthRepository());
  Either<Failure, bool>? mockResult;

  @override
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
  }) async {
    return mockResult ?? const Left(ServerFailure('Signup failed'));
  }
}

class MockSignOutUseCase extends SignOutUseCase {
  MockSignOutUseCase() : super(DummyAuthRepository());
  Either<Failure, void>? mockResult;

  @override
  Future<Either<Failure, void>> call() async {
    return mockResult ?? const Right(null);
  }
}

// Mock GoTrueClient
class MockGotrueClient implements sb.GoTrueClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  sb.User? mockUser;

  @override
  sb.User? get currentUser => mockUser;

  @override
  Stream<sb.AuthState> get onAuthStateChange => const Stream.empty();
}

// Mock SupabaseClient
class MockSupabaseClient implements sb.SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final MockGotrueClient _mockAuth = MockGotrueClient();

  @override
  sb.GoTrueClient get auth => _mockAuth;
}

void main() {
  final getIt = GetIt.instance;

  late MockLoginUseCase mockLoginUseCase;
  late MockSignupUseCase mockSignupUseCase;
  late MockSignOutUseCase mockSignOutUseCase;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    getIt.reset();
    mockLoginUseCase = MockLoginUseCase();
    mockSignupUseCase = MockSignupUseCase();
    mockSignOutUseCase = MockSignOutUseCase();
    mockSupabaseClient = MockSupabaseClient();

    // Register mocks in service locator
    getIt.registerSingleton<sb.SupabaseClient>(mockSupabaseClient);
    getIt.registerSingleton<LoginUseCase>(mockLoginUseCase);
    getIt.registerSingleton<SignupUseCase>(mockSignupUseCase);
    getIt.registerSingleton<SignOutUseCase>(mockSignOutUseCase);
  });

  group('AuthService Tests', () {
    test('handleLogin success path', () async {
      final authService = AuthService();
      
      final mockUser = sb.User(
        id: 'user123',
        email: 'test@example.com',
        createdAt: DateTime.now().toIso8601String(),
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        role: 'authenticated',
      );

      mockSupabaseClient._mockAuth.mockUser = mockUser;
      mockLoginUseCase.mockResult = Right(UserEntity(
        id: 'user123',
        email: 'test@example.com',
        fullName: 'Test User',
        username: 'testuser',
      ));

      final result = await authService.handleLogin('test@example.com', 'password123');

      expect(result, LoginResult.success);
      expect(authService.isUserSignedIn, true);
      expect(authService.currentUser?.id, 'user123');
      expect(authService.errorMessage, isNull);
    });

    test('handleLogin failure path', () async {
      final authService = AuthService();
      mockLoginUseCase.mockResult = const Left(ServerFailure('Invalid credentials'));

      final result = await authService.handleLogin('test@example.com', 'wrong_pass');

      expect(result, LoginResult.failure);
      expect(authService.isUserSignedIn, false);
      expect(authService.errorMessage, 'Invalid credentials');
    });

    test('handleSignup success path', () async {
      final authService = AuthService();
      mockSignupUseCase.mockResult = const Right(true);

      final result = await authService.handleSignup(
        email: 'new@example.com',
        password: 'password123',
        fullName: 'New User',
        phone: '1234567890',
        gender: 'male',
        birthdate: '2000-01-01',
      );

      expect(result, true);
      expect(authService.errorMessage, isNull);
    });

    test('handleSignup failure path', () async {
      final authService = AuthService();
      mockSignupUseCase.mockResult = const Left(ServerFailure('Email already exists'));

      final result = await authService.handleSignup(
        email: 'existing@example.com',
        password: 'password123',
        fullName: 'Existing User',
        phone: '1234567890',
        gender: 'male',
        birthdate: '2000-01-01',
      );

      expect(result, false);
      expect(authService.errorMessage, 'Email already exists');
    });
  });
}
