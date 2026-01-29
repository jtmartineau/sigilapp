import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../models/saved_sigil.dart';
import '../../services/sigil_storage_service.dart';

class DrawingStep extends StatefulWidget {
  final String incantation;
  final List<String> consonants;
  final String layoutType;
  final int polygonSides;
  final VoidCallback onRetryLayout;
  final VoidCallback onSigilCompleted;

  const DrawingStep({
    super.key,
    required this.incantation,
    required this.consonants,
    required this.layoutType,
    required this.polygonSides,
    required this.onRetryLayout,
    required this.onSigilCompleted,
  });

  @override
  State<DrawingStep> createState() => _DrawingStepState();
}

class _DrawingStepState extends State<DrawingStep> {
  // Store lines as lists of points
  final List<List<Offset>> _lines = [];
  List<Offset>? _currentLine;

  // For capturing the image
  final GlobalKey _canvasKey = GlobalKey();

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentLine = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentLine?.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentLine != null) {
      setState(() {
        _lines.add(List.from(_currentLine!));
        _currentLine = null;
      });
    }
  }

  void _undoLastLine() {
    if (_lines.isNotEmpty) {
      setState(() {
        _lines.removeLast();
      });
    }
  }

  Future<void> _handleBurn() async {
    // Show burning animation (placeholder: snackbar + delay)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Burning Sigil... 🔥')));
    await Future.delayed(const Duration(seconds: 2));
    widget.onSigilCompleted();
  }

  Future<void> _handleSave() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saving Sigil...')));

      // 1. Capture Image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Define a standard size for the saved image
      const size = Size(1000, 1000);

      // Draw background (black)
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black,
      );

      // Draw the sigil
      final painter = SigilCanvasPainter(
        consonants: widget.consonants,
        layoutType: widget.layoutType,
        polygonSides: widget.polygonSides,
        lines: _lines,
        currentLine: null,
        color: const Color(0xFFFFD700), // Gold
        textColor: Colors.white,
      );

      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      // 2. Save to Application Directory (for App usage)
      final directory = await getApplicationDocumentsDirectory();
      final String id = const Uuid().v4();
      final String fileName = 'sigil_$id.png';
      final File localFile = File('${directory.path}/$fileName');
      await localFile.writeAsBytes(buffer);

      // 3. Save Metadata
      final savedSigil = SavedSigil(
        id: id,
        incantation: widget.incantation,
        imagePath: localFile.path,
        dateCreated: DateTime.now(),
      );

      final storageService = SigilStorageService();
      await storageService.saveSigil(savedSigil);

      // 4. Save to Gallery (User requirement)
      // Note: This might require permissions on real devices
      // Gal handles permissions internally for Android < 10
      await Gal.putImageBytes(buffer, name: "SigilApp_$id");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sigil Saved to Grimoire & Gallery!')),
        );
        widget.onSigilCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasLines =
        _lines.isNotEmpty || (_currentLine != null && _currentLine!.isNotEmpty);

    return Column(
      children: [
        Text(
          'Draw your Sigil',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Connect the letters in order',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        // Drawing Area
        Expanded(
          child: Container(
            key: _canvasKey,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.primary),
              borderRadius: BorderRadius.circular(12),
              color: Colors.black12,
            ),
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: SigilCanvasPainter(
                  consonants: widget.consonants,
                  layoutType: widget.layoutType,
                  polygonSides: widget.polygonSides,
                  lines: _lines,
                  currentLine: _currentLine,
                  color: Theme.of(context).colorScheme.secondary, // Gold
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Controls
        if (!hasLines)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: widget.onRetryLayout,
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        if (hasLines) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _undoLastLine,
                icon: const Icon(Icons.undo),
                label: const Text('UNDO LINE'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Lock and show Finalize buttons
                  _showFinalizeDialog();
                },
                icon: const Icon(Icons.check),
                label: const Text('USE THIS SIGIL'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showFinalizeDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 200,
        child: Column(
          children: [
            Text(
              'Your Sigil is Ready',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleBurn();
                  },
                  icon: const Icon(Icons.local_fire_department),
                  label: const Text('BURN'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleSave();
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('SAVE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SigilCanvasPainter extends CustomPainter {
  final List<String> consonants;
  final String layoutType;
  final int polygonSides;
  final List<List<Offset>> lines;
  final List<Offset>? currentLine;
  final Color color; // Line color
  final Color textColor;

  SigilCanvasPainter({
    required this.consonants,
    required this.layoutType,
    required this.polygonSides,
    required this.lines,
    required this.currentLine,
    required this.color,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Layout Background (Faint)
    // Reuse logic from SigilLayoutPainter effectively, but maybe fainter
    _drawLayout(canvas, size);

    // 2. Draw User Lines
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      if (line.isEmpty) continue;
      final path = Path()..moveTo(line.first.dx, line.first.dy);
      for (int i = 1; i < line.length; i++) {
        path.lineTo(line[i].dx, line[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    if (currentLine != null && currentLine!.isNotEmpty) {
      final path = Path()..moveTo(currentLine!.first.dx, currentLine!.first.dy);
      for (int i = 1; i < currentLine!.length; i++) {
        path.lineTo(currentLine![i].dx, currentLine![i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawLayout(Canvas canvas, Size size) {
    // Copying logic from SigilLayoutPainter for consistency
    // Ideally this should be a shared helper or delegate
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 40;

    final layoutPaint = Paint()
      ..color = textColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    if (layoutType == 'Circle') {
      canvas.drawCircle(center, radius, layoutPaint);
      for (int i = 0; i < consonants.length; i++) {
        final angle = (2 * pi * i) / consonants.length - (pi / 2);
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);
        _drawLetter(canvas, textPainter, consonants[i], Offset(x, y));
      }
    } else {
      final vertices = <Offset>[];
      for (int i = 0; i < polygonSides; i++) {
        final angle = (2 * pi * i) / polygonSides - (pi / 2);
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);
        vertices.add(Offset(x, y));
      }
      // Draw polygon
      final path = Path();
      if (vertices.isNotEmpty) {
        path.moveTo(vertices[0].dx, vertices[0].dy);
        for (int i = 1; i < vertices.length; i++) {
          path.lineTo(vertices[i].dx, vertices[i].dy);
        }
        path.close();
      }
      canvas.drawPath(path, layoutPaint);

      for (int i = 0; i < consonants.length; i++) {
        final vertexIndex = i % polygonSides;
        final vertex = vertices[vertexIndex];
        final groupIndex = i ~/ polygonSides;
        final offsetAmount = 20.0 * groupIndex;
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
      style: TextStyle(
        color: textColor.withOpacity(0.5),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    tp.layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant SigilCanvasPainter oldDelegate) {
    return true; // Always repaint for drawing updates
  }
}
