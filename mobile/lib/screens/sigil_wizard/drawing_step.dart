import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added
import '../../utils/sigil_processor.dart'; // Added
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../models/saved_sigil.dart';
import '../../services/sigil_storage_service.dart';
import '../../services/api_service.dart'; // Added
import '../../services/auth_service.dart'; // Added
import '../../services/location_service.dart'; // Added

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

  Future<Uint8List> _captureSigil(Size size, Size originalSize) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background (matching app scaffold color)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF121212),
    );

    // Calculate scaling to match screen appearance
    final double targetRadius = min(size.width, size.height) / 2 - 40;
    final double sourceRadius =
        min(originalSize.width, originalSize.height) / 2 - 40;
    final double scale =
        targetRadius / max(sourceRadius, 1.0); // Avoid division by zero

    final Offset targetCenter = Offset(size.width / 2, size.height / 2);
    final Offset sourceCenter = Offset(
      originalSize.width / 2,
      originalSize.height / 2,
    );

    canvas.save();
    canvas.translate(targetCenter.dx, targetCenter.dy);
    canvas.scale(scale);
    canvas.translate(-sourceCenter.dx, -sourceCenter.dy);

    // Draw the sigil
    final painter = SigilCanvasPainter(
      consonants: widget.consonants,
      layoutType: widget.layoutType,
      polygonSides: widget.polygonSides,
      lines: _lines,
      currentLine: null,
      color: const Color(0xFFFFD700), // Gold
      textColor: Colors.white,
      onlyLines: true, // Only draw lines when capturing
    );

    painter.paint(canvas, originalSize);
    canvas.restore();

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _uploadSigil(
    Uint8List imageBytes,
    bool isBurned,
    String? token, {
    double? lat,
    double? long,
    String? id,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/temp_sigil.png');
    await file.writeAsBytes(imageBytes);

    final assignment = SigilProcessor.assignLetters(
      widget.consonants,
      widget.layoutType,
      widget.polygonSides,
    );

    await ApiService().uploadSigil(
      widget.incantation,
      file,
      isBurned,
      token,
      lat: lat,
      long: long,
      burnedLat: isBurned ? lat : null,
      burnedLong: isBurned ? long : null,
      layoutType: widget.layoutType,
      vertexCount: widget.polygonSides,
      letterAssignment: assignment,
      id: id,
    );

    // Cleanup
    await file.delete();
  }

  Future<void> _handleBurn() async {
    final token = context.read<AuthService>().token;
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Burning Sigil... 🔥')));

      final position = await LocationService().getCurrentLocation(context);

      // Get original size from the drawing widget
      final RenderBox? renderBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      final Size originalSize = renderBox?.size ?? const Size(400, 400);

      // Capture compressed version for upload
      final compressedBytes = await _captureSigil(
        const Size(800, 800),
        originalSize,
      );

      await _uploadSigil(
        compressedBytes,
        true,
        token,
        lat: position?.latitude,
        long: position?.longitude,
        id: const Uuid().v4(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sigil Burned Successfully!')),
        );
        widget.onSigilCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error burning: $e')));
      }
    }
  }

  Future<void> _handleSave() async {
    final token = context.read<AuthService>().token;
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saving Sigil...')));

      final position = await LocationService().getCurrentLocation(context);

      // Get original size from the drawing widget
      final RenderBox? renderBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      final Size originalSize = renderBox?.size ?? const Size(400, 400);

      // 1. Capture High-Res Image for Local Save
      final highResBytes = await _captureSigil(
        const Size(1000, 1000),
        originalSize,
      );

      // 2. Save to Application Directory (for App usage)
      final directory = await getApplicationDocumentsDirectory();
      final String id = const Uuid().v4();
      final String fileName = 'sigil_$id.png';
      final File localFile = File('${directory.path}/$fileName');
      await localFile.writeAsBytes(highResBytes);

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
      await Gal.putImageBytes(highResBytes, name: "SigilApp_$id");

      // 5. Upload Compressed Version
      try {
        final compressedBytes = await _captureSigil(
          const Size(800, 800),
          originalSize,
        );
        await _uploadSigil(
          compressedBytes,
          false,
          token,
          lat: position?.latitude,
          long: position?.longitude,
          id: id,
        );
      } catch (e) {
        debugPrint("Upload failed: $e");
        // We continue even if upload fails, as local save is primary here?
        // Or should we alert? "Saved locally but failed to sync".
        // For now, let's assume valid flow.
      }

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
              // border removed as requested
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
          Center(
            child: TextButton(
              onPressed: widget.onRetryLayout,
              child: const Text(
                'TRY AGAIN',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        if (hasLines) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 20,
              runSpacing: 10,
              children: [
                TextButton.icon(
                  onPressed: _undoLastLine,
                  icon: const Icon(Icons.undo, color: Color(0xFFFFD700)),
                  label: const Text(
                    'UNDO LINE',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Lock and show Finalize buttons
                    _showFinalizeDialog();
                  },
                  icon: const Icon(Icons.check, color: Color(0xFFFFD700)),
                  label: const Text(
                    'USE THIS SIGIL',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showFinalizeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900], // Dark background for contrast
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 200,
        child: Column(
          children: [
            Text(
              'Your Sigil is Ready',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleBurn();
                  },
                  icon: const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFFFD700),
                  ),
                  label: const Text(
                    'BURN',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleSave();
                  },
                  icon: const Icon(Icons.save, color: Color(0xFFFFD700)),
                  label: const Text(
                    'SAVE',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
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
  final bool onlyLines;

  SigilCanvasPainter({
    required this.consonants,
    required this.layoutType,
    required this.polygonSides,
    required this.lines,
    required this.currentLine,
    required this.color,
    required this.textColor,
    this.onlyLines = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Layout Background (Faint)
    // Reuse logic from SigilLayoutPainter effectively, but maybe fainter
    if (!onlyLines) {
      _drawLayout(canvas, size);
    }

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

      final groups = SigilProcessor.assignLetters(
        consonants,
        layoutType,
        polygonSides,
      );

      for (int i = 0; i < groups.length; i++) {
        if (i >= vertices.length) break;
        final vertex = vertices[i];
        final group = groups[i];
        final angle = (2 * pi * i) / polygonSides - (pi / 2);

        for (int j = 0; j < group.length; j++) {
          final letter = group[j];
          final offsetAmount = 25.0 * j;
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
