import '../../../../services/local_notification_service.dart';
import '../../../../services/sound_service.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  @override
  Future<void> showMessageNotification({
    required int id,
    required String senderName,
    required String message,
    String? payload,
  }) {
    return LocalNotificationService.showMessageNotification(
      id: id,
      senderName: senderName,
      message: message,
      payload: payload,
    );
  }

  @override
  Future<void> showLikeNotification({
    required int id,
    required String actorName,
    required String postSnippet,
    String? payload,
  }) {
    return LocalNotificationService.showLikeNotification(
      id: id,
      actorName: actorName,
      postSnippet: postSnippet,
      payload: payload,
    );
  }

  @override
  Future<void> showFollowNotification({
    required int id,
    required String actorName,
    String? payload,
  }) {
    return LocalNotificationService.showFollowNotification(
      id: id,
      actorName: actorName,
      payload: payload,
    );
  }

  @override
  Future<void> showMentionNotification({
    required int id,
    required String actorName,
    required String snippet,
    String? payload,
  }) {
    return LocalNotificationService.showMentionNotification(
      id: id,
      actorName: actorName,
      snippet: snippet,
      payload: payload,
    );
  }

  @override
  Future<void> showActivityNotification({
    required int id,
    required String actorName,
    required String action,
    String? payload,
  }) {
    return LocalNotificationService.showActivityNotification(
      id: id,
      actorName: actorName,
      action: action,
      payload: payload,
    );
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    return LocalNotificationService.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  @override
  void clearInbox() {
    LocalNotificationService.clearInbox();
  }

  @override
  Future<void> playPop() => SoundService.playPop();

  @override
  Future<void> playChime() => SoundService.playChime();

  @override
  Future<void> playSend() => SoundService.playSend();

  @override
  Future<void> playLike() => SoundService.playLike();

  @override
  Future<void> playComment() => SoundService.playComment();
}
