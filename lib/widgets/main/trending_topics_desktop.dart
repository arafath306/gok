import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

/// Desktop right-sidebar trending topics list.
///
/// [onTabChanged] is called with index `1` (Search tab) when a topic is tapped.
/// Using a callback instead of [findAncestorStateOfType] avoids a circular
/// import between this widget and [MainScreen].
class TrendingTopicsListDesktop extends StatefulWidget {
  final void Function(int) onTabChanged;

  const TrendingTopicsListDesktop({super.key, required this.onTabChanged});

  @override
  State<TrendingTopicsListDesktop> createState() =>
      _TrendingTopicsListDesktopState();
}

class _TrendingTopicsListDesktopState
    extends State<TrendingTopicsListDesktop> {
  List<String> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final trending = await dbService.fetchTrendingTopics();
    if (mounted) {
      setState(() {
        _topics = trending.map((t) => t['topic_name'] as String).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_topics.isEmpty) {
      return Text(
        "No trending topics yet.",
        style: GoogleFonts.inter(color: context.textSecondary),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _topics.length > 8 ? 8 : _topics.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final topic = _topics[index];
        final displayTopic = topic.startsWith('#') ? topic : '#$topic';
        return GestureDetector(
          onTap: () => widget.onTabChanged(1),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: Color(0xFF1E824C),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayTopic,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
