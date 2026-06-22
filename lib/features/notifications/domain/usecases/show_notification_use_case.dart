import '../repositories/notification_repository.dart';

enum NotificationType {
  message,
  like,
  follow,
  mention,
  activity,
  generic,
}

class ShowNotificationUseCase {
  final INotificationRepository repository;

  ShowNotificationUseCase(this.repository);

  Future<void> call({
    required NotificationType type,
    required int id,
    String? title,
    String? body,
    String? senderName,
    String? message,
    String? actorName,
    String? postSnippet,
    String? snippet,
    String? action,
    String? payload,
  }) {
    switch (type) {
      case NotificationType.message:
        return repository.showMessageNotification(
          id: id,
          senderName: senderName ?? 'Unknown',
          message: message ?? '',
          payload: payload,
        );
      case NotificationType.like:
        return repository.showLikeNotification(
          id: id,
          actorName: actorName ?? 'Someone',
          postSnippet: postSnippet ?? '',
          payload: payload,
        );
      case NotificationType.follow:
        return repository.showFollowNotification(
          id: id,
          actorName: actorName ?? 'Someone',
          payload: payload,
        );
      case NotificationType.mention:
        return repository.showMentionNotification(
          id: id,
          actorName: actorName ?? 'Someone',
          snippet: snippet ?? '',
          payload: payload,
        );
      case NotificationType.activity:
        return repository.showActivityNotification(
          id: id,
          actorName: actorName ?? 'Someone',
          action: action ?? '',
          payload: payload,
        );
      case NotificationType.generic:
        return repository.showNotification(
          id: id,
          title: title ?? '',
          body: body ?? '',
          payload: payload,
        );
    }
  }
}
