import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CustomMenuButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CustomMenuButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => Scaffold.of(context).openDrawer(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 2,
              decoration: BoxDecoration(
                color: context.textPrimary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 14,
              height: 2,
              decoration: BoxDecoration(
                color: context.textPrimary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 10,
              height: 2,
              decoration: BoxDecoration(
                color: context.textPrimary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
