import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/security/e2ee_service.dart';

import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_use_case.dart';
import '../features/auth/domain/usecases/signup_use_case.dart';
import '../features/auth/domain/usecases/sign_out_use_case.dart';

import '../features/feed/data/datasources/feed_remote_data_source.dart';
import '../features/feed/data/repositories/feed_repository_impl.dart';
import '../features/feed/domain/repositories/feed_repository.dart';
import '../features/feed/domain/usecases/get_feed_use_case.dart';
import '../features/feed/domain/usecases/create_thread_use_case.dart';
import '../features/feed/domain/usecases/toggle_like_use_case.dart';
import '../features/feed/domain/usecases/toggle_save_thread_use_case.dart';
import '../features/feed/domain/usecases/fetch_comments_use_case.dart';
import '../features/feed/domain/usecases/add_comment_use_case.dart';

import '../features/chat/data/datasources/chat_remote_data_source.dart';
import '../features/chat/data/repositories/chat_repository_impl.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/get_active_chats_use_case.dart';
import '../features/chat/domain/usecases/get_messages_stream_use_case.dart';
import '../features/chat/domain/usecases/send_message_use_case.dart';
import '../features/chat/domain/usecases/mark_messages_as_read_use_case.dart';
import '../features/chat/domain/usecases/delete_conversation_use_case.dart';
import '../features/chat/domain/usecases/upload_chat_media_use_case.dart';

import '../features/profile/data/datasources/profile_remote_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/usecases/submit_verification_use_case.dart';
import '../features/profile/domain/usecases/get_verification_status_use_case.dart';
import '../features/profile/domain/usecases/update_profile_use_case.dart';
import '../features/profile/domain/usecases/upload_verification_image_use_case.dart';
import '../features/profile/domain/usecases/update_profile_image_use_case.dart';
import '../features/profile/domain/usecases/fetch_verification_plans_use_case.dart';
import '../features/profile/domain/usecases/update_verification_plan_price_use_case.dart';
import '../features/profile/domain/usecases/fetch_admin_verification_requests_use_case.dart';
import '../features/profile/domain/usecases/update_verification_request_status_use_case.dart';

import '../features/notifications/data/repositories/notification_repository_impl.dart';
import '../features/notifications/domain/repositories/notification_repository.dart';
import '../features/notifications/domain/usecases/show_notification_use_case.dart';
import '../features/notifications/domain/usecases/play_sound_use_case.dart';
import '../features/notifications/domain/usecases/clear_notification_inbox_use_case.dart';

final sl = GetIt.instance;

Future<void> initInjection() async {
  // Supabase instance
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Security
  sl.registerLazySingleton<E2EEService>(() => E2EEService(sl()));

  // Features - Auth
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));

  // Repositories
  sl.registerLazySingleton<IAuthRepository>(() => AuthRepositoryImpl(sl()));

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignupUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));

  // Features - Feed
  // Data sources
  sl.registerLazySingleton<FeedRemoteDataSource>(() => FeedRemoteDataSourceImpl(sl()));

  // Repositories
  sl.registerLazySingleton<IFeedRepository>(() => FeedRepositoryImpl(sl(), sl()));

  // Use cases
  sl.registerLazySingleton(() => GetFeedUseCase(sl()));
  sl.registerLazySingleton(() => CreateThreadUseCase(sl()));
  sl.registerLazySingleton(() => ToggleLikeUseCase(sl()));
  sl.registerLazySingleton(() => ToggleSaveThreadUseCase(sl()));
  sl.registerLazySingleton(() => FetchCommentsUseCase(sl()));
  sl.registerLazySingleton(() => AddCommentUseCase(sl()));

  // Features - Chat
  // Data sources
  sl.registerLazySingleton<ChatRemoteDataSource>(() => ChatRemoteDataSourceImpl(sl(), sl()));

  // Repositories
  sl.registerLazySingleton<IChatRepository>(() => ChatRepositoryImpl(sl(), sl(), sl()));

  // Use cases
  sl.registerLazySingleton(() => GetActiveChatsUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesStreamUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => MarkMessagesAsReadUseCase(sl()));
  sl.registerLazySingleton(() => DeleteConversationUseCase(sl()));
  sl.registerLazySingleton(() => UploadChatMediaUseCase(sl()));

  // Features - Profile
  // Data sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(() => ProfileRemoteDataSourceImpl(sl()));

  // Repositories
  sl.registerLazySingleton<IProfileRepository>(() => ProfileRepositoryImpl(sl(), sl()));

  // Use cases
  sl.registerLazySingleton(() => SubmitVerificationUseCase(sl()));
  sl.registerLazySingleton(() => GetVerificationStatusUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => UploadVerificationImageUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileImageUseCase(sl()));
  sl.registerLazySingleton(() => FetchVerificationPlansUseCase(sl()));
  sl.registerLazySingleton(() => UpdateVerificationPlanPriceUseCase(sl()));
  sl.registerLazySingleton(() => FetchAdminVerificationRequestsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateVerificationRequestStatusUseCase(sl()));

  // Features - Notifications
  // Repositories
  sl.registerLazySingleton<INotificationRepository>(() => NotificationRepositoryImpl());

  // Use cases
  sl.registerLazySingleton(() => ShowNotificationUseCase(sl()));
  sl.registerLazySingleton(() => PlaySoundUseCase(sl()));
  sl.registerLazySingleton(() => ClearNotificationInboxUseCase(sl()));
}
