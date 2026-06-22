abstract class INotificationRepository {
  Future<void> showMessageNotification({
    required int id,
    required String senderName,
    required String message,
    String? payload,
  });

  Future<void> showLikeNotification({
    required int id,
    required String actorName,
    required String postSnippet,
    String? payload,
  });

  Future<void> showFollowNotification({
    required int id,
    required String actorName,
    String? payload,
  });

  Future<void> showMentionNotification({
    required int id,
    required String actorName,
    required String snippet,
    String? payload,
  });

  Future<void> showActivityNotification({
    required int id,
    required String actorName,
    required String action,
    String? payload,
  });

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  void clearInbox();

  // Sound operations
  Future<void> playPop();
  Future<void> playChime();
  Future<void> playSend();
  Future<void> playLike();
  Future<void> playComment();
}
