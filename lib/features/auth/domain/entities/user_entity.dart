class UserEntity {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final String? phone;
  final String? birthdate;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    this.phone,
    this.birthdate,
  });
}
