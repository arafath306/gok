class MessageEntity {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final String createdAt;
  final String? mediaUrl;
  final String? mediaType;
  final bool isRead;

  MessageEntity({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    required this.createdAt,
    this.mediaUrl,
    this.mediaType,
    required this.isRead,
  });
}
