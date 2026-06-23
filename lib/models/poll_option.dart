class PollOption {
  final String id;
  final String threadId;
  final String optionText;
  final int votesCount;

  PollOption({
    required this.id,
    required this.threadId,
    required this.optionText,
    this.votesCount = 0,
  });

  factory PollOption.fromJson(Map<String, dynamic> json, {List<dynamic>? votesList}) {
    final optionId = json['id'] as String;
    
    // Calculate votes count either from cached count or dynamically from joined votesList
    int count = 0;
    if (votesList != null) {
      count = votesList.where((vote) => vote['poll_option_id'] == optionId).length;
    } else {
      count = (json['votes_count'] as int?) ?? 0;
    }

    return PollOption(
      id: optionId,
      threadId: json['thread_id'] as String,
      optionText: json['option_text'] as String,
      votesCount: count,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thread_id': threadId,
      'option_text': optionText,
      'votes_count': votesCount,
    };
  }

  PollOption copyWith({
    String? id,
    String? threadId,
    String? optionText,
    int? votesCount,
  }) {
    return PollOption(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      optionText: optionText ?? this.optionText,
      votesCount: votesCount ?? this.votesCount,
    );
  }
}
