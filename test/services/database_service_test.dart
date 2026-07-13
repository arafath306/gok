import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:get_it/get_it.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/core/error/failures.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/features/feed/domain/entities/thread_post_entity.dart';
import 'package:dak/features/feed/domain/usecases/get_feed_use_case.dart';
import 'package:dak/features/feed/domain/repositories/feed_repository.dart';

class DummyFeedRepository implements IFeedRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock GetFeedUseCase
class MockGetFeedUseCase extends GetFeedUseCase {
  MockGetFeedUseCase() : super(DummyFeedRepository());
  Either<Failure, List<ThreadPostEntity>>? mockResult;

  @override
  Future<Either<Failure, List<ThreadPostEntity>>> call({bool silent = false}) async {
    return mockResult ?? const Left(ServerFailure('Feed load failed'));
  }
}

// Mock SupabaseClient
class MockSupabaseClient extends sb.SupabaseClient {
  MockSupabaseClient() : super(
    'https://mock.supabase.co',
    'mockKey',
  );
}

void main() {
  final getIt = GetIt.instance;

  late MockGetFeedUseCase mockGetFeedUseCase;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    getIt.reset();
    mockGetFeedUseCase = MockGetFeedUseCase();
    mockSupabaseClient = MockSupabaseClient();

    // Register mocks
    getIt.registerSingleton<sb.SupabaseClient>(mockSupabaseClient);
    getIt.registerSingleton<GetFeedUseCase>(mockGetFeedUseCase);
  });

  group('DatabaseService Tests', () {
    test('fetchFeed success path updates feed property', () async {
      final dbService = DatabaseService();

      final mockEntity = ThreadPostEntity(
        id: 'post1',
        userId: 'user1',
        author: Profile(id: 'user1', username: 'john', fullName: 'john'),
        content: 'Mock post content',
        createdAt: DateTime.now().toIso8601String(),
      );

      mockGetFeedUseCase.mockResult = Right([mockEntity]);

      expect(dbService.isLoading, false);
      expect(dbService.feed.isEmpty, true);

      await dbService.fetchFeed();

      expect(dbService.isLoading, false);
      expect(dbService.feed.length, 1);
      expect(dbService.feed[0].id, 'post1');
      expect(dbService.feed[0].content, 'Mock post content');
    });

    test('fetchFeed failure path keeps feed empty and logs error', () async {
      final dbService = DatabaseService();
      mockGetFeedUseCase.mockResult = const Left(ServerFailure('Network issue'));

      await dbService.fetchFeed();

      expect(dbService.isLoading, false);
      expect(dbService.feed.isEmpty, true);
    });
  });
}
