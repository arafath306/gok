import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';

class IdUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final XFile? file;
  final VoidCallback onTap;

  const IdUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: file != null ? context.primaryAccent : context.border,
            width: file != null ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: file == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: context.primaryAccent, size: 28),
                    const SizedBox(height: 8),
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                            fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: context.textSecondary, fontSize: 11.5)),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder<Uint8List>(
                    future: file!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
