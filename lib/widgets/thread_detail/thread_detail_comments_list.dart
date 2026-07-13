import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/thread_post.dart';
import '../../models/profile.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../comment_item.dart';

class ThreadDetailCommentsList extends StatelessWidget {
  final ThreadPost post;
  final List<Map<String, dynamic>> topLevelComments;
  final bool isLoadingComments;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onReloadComments;
  final Function(String) onCommentDeleted;
  final Function(String) onCommentHidden;
  final DatabaseService dbService;

  const ThreadDetailCommentsList({
    super.key,
    required this.post,
    required this.topLevelComments,
    required this.isLoadingComments,
    required this.sortBy,
    required this.onSortChanged,
    required this.onReloadComments,
    required this.onCommentDeleted,
    required this.onCommentHidden,
    required this.dbService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments section header with filter dropdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          color: context.isDarkMode ? const Color(0xFF0A0B10) : Colors.grey[50],
          child: Row(
            children: [
              DropdownButton<String>(
                value: sortBy,
                underline: const SizedBox(),
                dropdownColor: context.cardBg,
                icon: Icon(Icons.keyboard_arrow_down,
                    size: 18, color: context.textPrimary),
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: ["Most relevant", "Newest", "Oldest"].map((val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(
                      val,
                      style: GoogleFonts.inter(color: context.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    onSortChanged(val);
                  }
                },
              ),
            ],
          ),
        ),

        // Comments List
        if (isLoadingComments)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor)),
          )
        else if (topLevelComments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                "No comments found.",
                style: GoogleFonts.inter(color: context.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topLevelComments.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: context.border),
            itemBuilder: (context, index) {
              final comment = topLevelComments[index];
              final author = comment['author'] as Profile;
              return CommentItem(
                comment: comment,
                effectiveThreadId: post.id,
                dbService: dbService,
                post: post,
                isPostAuthor: author.id == post.userId,
                index: index,
                isLast: index == (topLevelComments.length - 1),
                onReloadComments: onReloadComments,
                onCommentDeleted: onCommentDeleted,
                onCommentHidden: onCommentHidden,
              );
            },
          ),
      ],
    );
  }
}
