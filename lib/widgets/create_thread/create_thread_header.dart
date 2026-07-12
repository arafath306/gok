import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class CreateThreadHeader extends StatelessWidget {
  final VoidCallback onClose;
  final int draftCount;
  final bool isEditMode;
  final bool isQuoteMode;
  final VoidCallback onDraftsPressed;
  final bool showSaveDraftButton;
  final VoidCallback onSaveDraftPressed;
  final bool isSubmitEnabled;
  final VoidCallback onSubmitPressed;
  final bool isUploadingImage;

  const CreateThreadHeader({
    super.key,
    required this.onClose,
    required this.draftCount,
    required this.isEditMode,
    required this.isQuoteMode,
    required this.onDraftsPressed,
    required this.showSaveDraftButton,
    required this.onSaveDraftPressed,
    required this.isSubmitEnabled,
    required this.onSubmitPressed,
    required this.isUploadingImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 8),
      color: context.cardBg,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: context.textPrimary),
            onPressed: onClose,
          ),
          if (draftCount > 0 && !isEditMode && !isQuoteMode)
            TextButton(
              onPressed: onDraftsPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: const Color(0xFF1E824C),
              ),
              child: Text(
                "Drafts ($draftCount)",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          const Spacer(),
          if (showSaveDraftButton && !isEditMode && !isQuoteMode)
            TextButton(
              onPressed: onSaveDraftPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: context.textPrimary,
              ),
              child: Text(
                "Draft",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ElevatedButton(
            onPressed: isSubmitEnabled ? onSubmitPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E824C),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
              disabledForegroundColor: Colors.grey.withValues(alpha: 0.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: isUploadingImage
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isEditMode ? "Save" : "Release",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
          )
        ],
      ),
    );
  }
}
