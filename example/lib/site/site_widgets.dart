import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';

class SiteBrand extends StatelessWidget {
  const SiteBrand({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 132,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: FTheme.of(context).colors.foreground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.polyline_outlined,
                  color: FTheme.of(context).colors.background,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'flappa',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              Text(
                ' / ui',
                style: TextStyle(
                  fontSize: 20,
                  color: FTheme.of(context).colors.mutedForeground,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DotGridPainter extends CustomPainter {
  const DotGridPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 12; x < size.width; x += 24) {
      for (double y = 12; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), .8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter oldDelegate) => oldDelegate.color != color;
}
