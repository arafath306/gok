import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/thread_post.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_thread_card.dart';
import '../../widgets/thread_shimmer.dart';
import '../../utils/app_theme.dart';

class TopicThreadsScreen extends StatefulWidget {
  final String topicName;
  const TopicThreadsScreen({super.key, required this.topicName});

  @override
  State<TopicThreadsScreen> createState() => _TopicThreadsScreenState();
}

class _TopicThreadsScreenState extends State<TopicThreadsScreen> {
  List<ThreadPost> _threads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopicThreads();
  }

  Future<void> _loadTopicThreads() async {
    setState(() => _isLoading = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final threads = await dbService.fetchTopicThreads(widget.topicName);
    if (mounted) {
      setState(() {
        _threads = threads;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanName = widget.topicName.startsWith('#') ? widget.topicName : '#${widget.topicName}';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          cleanName,
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1E824C),
        onRefresh: _loadTopicThreads,
        child: _isLoading
            ? const ThreadShimmer()
            : _threads.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.tag_rounded, size: 48, color: context.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                "No posts found for this topic",
                                style: GoogleFonts.inter(
                                  color: context.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _threads.length,
                    padding: const EdgeInsets.only(bottom: 32),
                    itemBuilder: (context, index) {
                      final post = _threads[index];
                      return CustomThreadCard(
                        key: ValueKey(post.id),
                        post: post,
                      );
                    },
                  ),
      ),
    );
  }
}
