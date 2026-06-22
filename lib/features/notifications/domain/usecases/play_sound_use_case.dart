import '../repositories/notification_repository.dart';

enum SoundType {
  pop,
  chime,
  send,
  like,
  comment,
}

class PlaySoundUseCase {
  final INotificationRepository repository;

  PlaySoundUseCase(this.repository);

  Future<void> call(SoundType type) {
    switch (type) {
      case SoundType.pop:
        return repository.playPop();
      case SoundType.chime:
        return repository.playChime();
      case SoundType.send:
        return repository.playSend();
      case SoundType.like:
        return repository.playLike();
      case SoundType.comment:
        return repository.playComment();
    }
  }
}
