import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/community.dart';
import '../../models/thread_post.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_thread_card.dart';

class CommunityThreadSearchScreen extends StatefulWidget {
  final Community community;

  const CommunityThreadSearchScreen({super.key, required this.community});

  @override
  State<CommunityThreadSearchScreen> createState() => _CommunityThreadSearchScreenState();
}

class _CommunityThreadSearchScreenState extends State<CommunityThreadSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ThreadPost> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final trimmed = query.trim();
    if (trimmed == _lastQuery) return;
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _lastQuery = trimmed;
      if (trimmed.isEmpty) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isLoading = false;
          });
        }
        return;
      }
      _performSearch(trimmed);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final results = await dbService.searchThreads(query, communityId: widget.community.id);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.inter(color: context.textPrimary, fontSize: 15),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search in ${widget.community.name}',
                hintStyle: GoogleFonts.inter(color: context.textSecondary, fontSize: 15),
                prefixIcon: Icon(CupertinoIcons.search, color: context.textSecondary, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: context.textSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.search, size: 48, color: context.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Search for posts in ${widget.community.name}',
              style: GoogleFonts.inter(
                color: context.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: context.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No posts found for "${_searchController.text.trim()}"',
              style: GoogleFonts.inter(
                color: context.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        color: context.border,
      ),
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return CustomThreadCard(post: post);
      },
    );
  }
}
