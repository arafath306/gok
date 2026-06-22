import '../repositories/notification_repository.dart';

class ClearNotificationInboxUseCase {
  final INotificationRepository repository;

  ClearNotificationInboxUseCase(this.repository);

  void call() {
    repository.clearInbox();
  }
}
