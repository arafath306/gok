import 'dart:typed_data';
import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class UploadVerificationImageUseCase {
  final IProfileRepository repository;

  UploadVerificationImageUseCase(this.repository);

  Future<Either<Failure, String?>> call(Uint8List bytes, String filename) {
    return repository.uploadVerificationImage(bytes, filename);
  }
}
