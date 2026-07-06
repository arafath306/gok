class CommunityRule {
  final String id;
  final String communityId;
  final String title;
  final String description;
  final int ruleOrder;
  final DateTime createdAt;

  CommunityRule({
    required this.id,
    required this.communityId,
    required this.title,
    required this.description,
    required this.ruleOrder,
    required this.createdAt,
  });

  factory CommunityRule.fromJson(Map<String, dynamic> json) {
    return CommunityRule(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      ruleOrder: json['rule_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
