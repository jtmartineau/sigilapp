import 'package:flutter/material.dart';
import 'sigil_layout_painter.dart';

class LayoutSelectionStep extends StatefulWidget {
  final List<String> consonants;
  final Function(String, int) onLayoutConfirmed;

  const LayoutSelectionStep({
    super.key,
    required this.consonants,
    required this.onLayoutConfirmed,
  });

  @override
  State<LayoutSelectionStep> createState() => _LayoutSelectionStepState();
}

class _LayoutSelectionStepState extends State<LayoutSelectionStep> {
  String _selectedLayout = 'Circle';
  double _polygonSides = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Choose your layout',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        // Layout Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Circle'),
              selected: _selectedLayout == 'Circle',
              onSelected: (selected) {
                if (selected) setState(() => _selectedLayout = 'Circle');
              },
            ),
            const SizedBox(width: 16),
            ChoiceChip(
              label: const Text('Polygon'),
              selected: _selectedLayout == 'Polygon',
              onSelected: (selected) {
                if (selected) setState(() => _selectedLayout = 'Polygon');
              },
            ),
          ],
        ),
        if (_selectedLayout == 'Polygon') ...[
          const SizedBox(height: 16),
          Text('Sides: ${_polygonSides.toInt()}'),
          Slider(
            value: _polygonSides,
            min: 2,
            max: 12,
            divisions: 10,
            onChanged: (val) {
              setState(() => _polygonSides = val);
            },
          ),
        ],
        const SizedBox(height: 24),
        // Preview Area
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              // border removed as requested
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: SigilLayoutPainter(
                consonants: widget.consonants,
                layoutType: _selectedLayout,
                polygonSides: _polygonSides.toInt(),
                color: Theme.of(context).colorScheme.onSurface,
              ),
              child: Container(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 10,
            children: [
              TextButton(
                onPressed: () {
                  // Back logic...
                },
                child: const Text(
                  'BACK',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onLayoutConfirmed(
                    _selectedLayout,
                    _polygonSides.toInt(),
                  );
                },
                child: const Text(
                  'USE THIS LAYOUT',
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
    );
  }
}
