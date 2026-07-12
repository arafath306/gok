import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class VoiceRecorderUI extends StatelessWidget {
  final bool isRecording;
  final int recordingSeconds;
  final VoidCallback onToggleRecording;
  final VoidCallback onClose;

  const VoiceRecorderUI({
    super.key,
    required this.isRecording,
    required this.recordingSeconds,
    required this.onToggleRecording,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = (recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (recordingSeconds % 60).toString().padLeft(2, '0');
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF062D1C) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isRecording ? Icons.mic : Icons.mic_none,
            color: Colors.teal,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isRecording ? "Recording... ($minutes:$seconds)" : "Voice recorder ready",
            style: GoogleFonts.inter(
              color: Colors.teal,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onToggleRecording,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isRecording ? Colors.red : Colors.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isRecording ? "Stop" : "Start",
                style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 18, color: context.textSecondary),
          )
        ],
      ),
    );
  }
}
