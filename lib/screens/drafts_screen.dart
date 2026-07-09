import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/draft_post.dart';
import '../services/draft_service.dart';
import '../utils/app_theme.dart';
import '../utils/routes.dart';
import 'create_thread_screen.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  final DraftService _draftService = DraftService();
  List<DraftPost> _drafts = [];
  bool _isLoading = true;
  
  bool _isEditing = false;
  final Set<String> _selectedDraftIds = {};

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoading = true);
    final drafts = await _draftService.getDrafts();
    setState(() {
      _drafts = drafts;
      _isLoading = false;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      _selectedDraftIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedDraftIds.contains(id)) {
        _selectedDraftIds.remove(id);
      } else {
        _selectedDraftIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedDraftIds.length == _drafts.length) {
        _selectedDraftIds.clear();
      } else {
        _selectedDraftIds.addAll(_drafts.map((d) => d.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedDraftIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Delete Drafts",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Text(
          "Are you sure you want to delete ${_selectedDraftIds.length} selected draft(s)? This action cannot be undone.",
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.inter(color: context.textPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("Delete", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _draftService.deleteDrafts(_selectedDraftIds.toList());
      setState(() {
        _isEditing = false;
        _selectedDraftIds.clear();
      });
      _loadDrafts();
    }
  }

  void _openDraft(DraftPost draft) {
    if (_isEditing) {
      _toggleSelection(draft.id);
      return;
    }
    
    Navigator.push(
      context,
      NoTransitionPageRoute(
        child: CreateThreadScreen(draftPost: draft),
      ),
    ).then((_) {
      // Reload drafts when returning from composer, in case it was updated or deleted
      _loadDrafts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "Drafts",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_drafts.isNotEmpty)
            TextButton(
              onPressed: _toggleEditMode,
              child: Text(
                _isEditing ? "Done" : "Edit",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E824C),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: context.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)))
          : _drafts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_document, size: 48, color: context.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        "No saved drafts",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _drafts.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: context.border, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final draft = _drafts[index];
                    final isSelected = _selectedDraftIds.contains(draft.id);
                    
                    String previewText = draft.content;
                    if (previewText.isEmpty) {
                      if (draft.imagePaths.isNotEmpty) {
                        previewText = "[Image attached]";
                      } else if (draft.videoUrl != null) {
                        previewText = "[Video attached]";
                      } else if (draft.pollOptions != null) {
                        previewText = "[Poll attached]";
                      } else {
                        previewText = "Empty draft";
                      }
                    }

                    return InkWell(
                      onTap: () => _openDraft(draft),
                      onLongPress: () {
                        if (!_isEditing) {
                          _toggleEditMode();
                          _toggleSelection(draft.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: isSelected ? const Color(0xFF1E824C).withValues(alpha: 0.1) : Colors.transparent,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isEditing)
                              Padding(
                                padding: const EdgeInsets.only(right: 12, top: 4),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (val) => _toggleSelection(draft.id),
                                    activeColor: const Color(0xFF1E824C),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          previewText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            color: context.textPrimary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      if (draft.imagePaths.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.file(
                                              File(draft.imagePaths.first),
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 48,
                                                height: 48,
                                                color: context.border,
                                                child: const Icon(Icons.broken_image, size: 20),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('MMM d, h:mm a').format(draft.updatedAt),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                      if (draft.imagePaths.length > 1) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.photo_library, size: 12, color: context.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          "+${draft.imagePaths.length - 1}",
                                          style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                                        ),
                                      ],
                                      if (draft.location != null) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.location_on, size: 12, color: context.textMuted),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: _isEditing && _drafts.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.cardBg,
                border: Border(top: BorderSide(color: context.border, width: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _selectAll,
                      child: Text(
                        _selectedDraftIds.length == _drafts.length ? "Deselect All" : "Select All",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectedDraftIds.isEmpty ? null : _deleteSelected,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text("Delete (${_selectedDraftIds.length})"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
