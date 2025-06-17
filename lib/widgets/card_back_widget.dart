import 'package:flutter/material.dart';

class CardBackWidget extends StatelessWidget {
  final double width;
  final double height;

  const CardBackWidget({
    super.key,
    this.width = 48,
    this.height = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/game/back_carte.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class CardBackPatternPainter extends CustomPainter {
  final bool isOpponent;

  CardBackPatternPainter({required this.isOpponent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Disegna pattern geometrico
    for (int i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(
        size.width * 0.1 + (i * 4),
        size.height * 0.1 + (i * 4),
        size.width * 0.8 - (i * 8),
        size.height * 0.8 - (i * 8),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }

    // Disegna piccoli rombi agli angoli
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white.withOpacity(0.15);

    final diamondSize = size.width * 0.08;
    _drawDiamond(canvas, paint, Offset(diamondSize, diamondSize), diamondSize);
    _drawDiamond(canvas, paint, Offset(size.width - diamondSize, diamondSize),
        diamondSize);
    _drawDiamond(canvas, paint, Offset(diamondSize, size.height - diamondSize),
        diamondSize);
    _drawDiamond(
        canvas,
        paint,
        Offset(size.width - diamondSize, size.height - diamondSize),
        diamondSize);
  }

  void _drawDiamond(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size / 2);
    path.lineTo(center.dx + size / 2, center.dy);
    path.lineTo(center.dx, center.dy + size / 2);
    path.lineTo(center.dx - size / 2, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
