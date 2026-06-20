import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/app_theme.dart';

class SavedThreadsScreen extends StatelessWidget {
  const SavedThreadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved Posts',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: Consumer<GeneralSettingsProvider>(
        builder: (context, provider, _) {
          final threads = provider.savedThreads;
          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 60, color: context.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No saved posts yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Save posts to read them later.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: threads.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final thread = threads[index];
              return _buildThreadCard(context, provider, thread);
            },
          );
        },
      ),
    );
  }

  Widget _buildThreadCard(BuildContext context, GeneralSettingsProvider provider, Map<String, dynamic> thread) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(thread['author_avatar']),
                backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread['author_name'],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      '@${thread['author_username']}  ·  ${thread['time_ago']}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.bookmark_added_rounded, color: context.primaryAccent, size: 22),
                onPressed: () {
                  provider.unsaveThread(thread['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Post unsaved successfully'),
                      backgroundColor: context.primaryAccent,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            thread['content'],
            style: GoogleFonts.hindSiliguri(
              fontSize: 14.5,
              color: context.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border_rounded, size: 16, color: context.textMuted),
              const SizedBox(width: 4),
              Text(
                '${thread['likes']}',
                style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
              ),
              const SizedBox(width: 16),
              Icon(Icons.mode_comment_outlined, size: 16, color: context.textMuted),
              const SizedBox(width: 4),
              Text(
                '${thread['replies']}',
                style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
