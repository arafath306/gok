import 'dart:typed_data';
import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileImageUseCase {
  final IProfileRepository repository;

  UpdateProfileImageUseCase(this.repository);

  Future<Either<Failure, bool>> call(Uint8List bytes, bool isAvatar) {
    return repository.updateProfileImage(bytes, isAvatar);
  }
}
