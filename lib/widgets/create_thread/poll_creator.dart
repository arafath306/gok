import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class PollCreator extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onClose;
  final Function(int index) onRemoveOption;
  final VoidCallback onAddOption;
  final Duration selectedDuration;
  final List<Map<String, dynamic>> durations;
  final Function(Duration) onDurationChanged;

  const PollCreator({
    super.key,
    required this.controllers,
    required this.onClose,
    required this.onRemoveOption,
    required this.onAddOption,
    required this.selectedDuration,
    required this.durations,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF201608) : const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: context.isDarkMode ? 0.05 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Create Interactive Poll",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close_rounded, size: 20, color: context.textSecondary),
              )
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(controllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controllers[index],
                      maxLength: 25,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: InputDecoration(
                        hintText: "Option ${index + 1}",
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textMuted),
                        filled: true,
                        fillColor: context.isDarkMode ? const Color(0xFF1E2030) : Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
                        ),
                        counterText: "",
                      ),
                      style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
                    ),
                  ),
                  if (controllers.length > 2) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onRemoveOption(index),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                      ),
                    ),
                  ]
                ],
              ),
            );
          }),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 12,
            children: [
              if (controllers.length < 4)
                TextButton.icon(
                  onPressed: onAddOption,
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.orange),
                  label: Text(
                    "Add Option",
                    style: GoogleFonts.inter(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              else
                const SizedBox.shrink(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Duration: ",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? const Color(0xFF1E2030) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Duration>(
                        value: selectedDuration,
                        dropdownColor: context.cardBg,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.orange),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: context.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (Duration? val) {
                          if (val != null) {
                            onDurationChanged(val);
                          }
                        },
                        items: durations.map((d) {
                          return DropdownMenuItem<Duration>(
                            value: d["duration"] as Duration,
                            child: Text(d["label"] as String),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
