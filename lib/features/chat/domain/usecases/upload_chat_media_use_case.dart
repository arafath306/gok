import 'dart:typed_data';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class UploadChatMediaUseCase {
  final IChatRepository repository;

  UploadChatMediaUseCase(this.repository);

  Future<Either<Failure, String?>> call(Uint8List bytes) {
    return repository.uploadChatMedia(bytes);
  }
}
