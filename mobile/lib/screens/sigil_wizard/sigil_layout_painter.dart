import 'package:flutter/material.dart';
import 'dart:math';

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
      // "assigned ... to successive points"
      for (int i = 0; i < consonants.length; i++) {
        final vertexIndex = i % polygonSides;
        final vertex = vertices[vertexIndex];

        // To avoid stacking text exactly on top of each other if multiple letters per vertex,
        // we might need a slight offset or just stack them.
        // Requirement says "displayed as groups ... around each point"
        // Let's stack them slightly outward or just list them.

        // Simple implementation: Just put them at the vertex.
        // Better: Slight offset based on how many times we've visited this vertex?
        final groupIndex = i ~/ polygonSides;
        final offsetAmount = 20.0 * groupIndex;

        // Calculate direction from center to vertex to push outward
        final angle = (2 * pi * vertexIndex) / polygonSides - (pi / 2);
        final letterPos = Offset(
          vertex.dx + (offsetAmount * cos(angle)),
          vertex.dy + (offsetAmount * sin(angle)),
        );

        _drawLetter(canvas, textPainter, consonants[i], letterPos);
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
