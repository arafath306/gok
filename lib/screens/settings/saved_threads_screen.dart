import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/general_settings_provider.dart';

class SavedThreadsScreen extends StatelessWidget {
  const SavedThreadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved Posts',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFEEEEEE), height: 1.0),
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
                  const Icon(Icons.bookmark_border_rounded, size: 60, color: Colors.black26),
                  const SizedBox(height: 16),
                  Text(
                    'No saved posts yet',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Save posts to read them later.',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: threads.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
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
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(thread['author_avatar']),
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread['author_name'],
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '@${thread['author_username']}  ·  ${thread['time_ago']}',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_added_rounded, color: Color(0xFF1E824C), size: 22),
                onPressed: () {
                  provider.unsaveThread(thread['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post unsaved successfully'),
                      backgroundColor: Color(0xFF1E824C),
                      duration: Duration(seconds: 1),
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
              color: Colors.black87,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite_border_rounded, size: 16, color: Colors.black38),
              const SizedBox(width: 4),
              Text(
                '${thread['likes']}',
                style: GoogleFonts.outfit(fontSize: 12.5, color: Colors.black45),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.black38),
              const SizedBox(width: 4),
              Text(
                '${thread['replies']}',
                style: GoogleFonts.outfit(fontSize: 12.5, color: Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
