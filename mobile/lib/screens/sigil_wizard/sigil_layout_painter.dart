import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/sigil_processor.dart';

class SigilLayoutPainter extends CustomPainter {
  final List<String> consonants;
  final String layoutType; // 'Circle' or 'Polygon'
  final int polygonSides;
  final Color color;

  SigilLayoutPainter({
    required this.consonants,
    required this.layoutType,
    required this.polygonSides,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20; // Padding

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw the guiding shape (optional, but helpful)
    if (layoutType == 'Circle') {
      canvas.drawCircle(center, radius, paint..color = color.withOpacity(0.3));

      // Draw letters around circle
      for (int i = 0; i < consonants.length; i++) {
        final angle =
            (2 * pi * i) / consonants.length - (pi / 2); // Start at top
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);

        _drawLetter(canvas, textPainter, consonants[i], Offset(x, y));
      }
    } else {
      // Polygon
      // Draw the polygon
      final path = Path();
      final vertices = <Offset>[];

      for (int i = 0; i < polygonSides; i++) {
        final angle = (2 * pi * i) / polygonSides - (pi / 2);
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);
        vertices.add(Offset(x, y));

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint..color = color.withOpacity(0.3));

      // Draw letters at vertices
      final groups = SigilProcessor.assignLetters(
        consonants,
        layoutType,
        polygonSides,
      );

      for (int i = 0; i < groups.length; i++) {
        if (i >= vertices.length) break;
        final vertex = vertices[i];
        final group = groups[i];

        // Calculate direction from center to vertex to push outward
        final angle = (2 * pi * i) / polygonSides - (pi / 2);

        for (int j = 0; j < group.length; j++) {
          final letter = group[j];
          final offsetAmount = 25.0 * j; // Stack/Spread outward

          final letterPos = Offset(
            vertex.dx + (offsetAmount * cos(angle)),
            vertex.dy + (offsetAmount * sin(angle)),
          );

          _drawLetter(canvas, textPainter, letter, letterPos);
        }
      }
    }
  }

  void _drawLetter(Canvas canvas, TextPainter tp, String letter, Offset pos) {
    tp.text = TextSpan(
      text: letter,
      style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
    );
    tp.layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant SigilLayoutPainter oldDelegate) {
    return oldDelegate.consonants != consonants ||
        oldDelegate.layoutType != layoutType ||
        oldDelegate.polygonSides != polygonSides;
  }
}
