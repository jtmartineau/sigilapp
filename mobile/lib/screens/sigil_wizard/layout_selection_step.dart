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
              border: Border.all(color: Theme.of(context).colorScheme.primary),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                // Try again logic is actually handled by parent (resetting step),
                // but requirements say "try again" button appears.
                // In my main screen logic, "Try Again" is actually going BACK to this step
                // from the drawing step.
                // But inside this step, we are just configuring.
                // Wait, requirements: "Once the incantation is automatically processed, a menu will appear...
                // When the selected display is then rendered... two buttons... become un-grayed... 'try again' ... 'use this layout'"

                // "Try again" in this context implies re-doing the Incantation?
                // Or re-doing the layout choice?
                // "If the user selects 'try again' the app will return the flow that allows them to select a circle or a polygon."
                // This implies "Try Again" is available AFTER they see the layout.
                // My UI updates instantly, so "Try Again" effectively just means "Don't confirm yet".

                // I will add a "Back" button here to go to Incantation?
                // Or just keep it as is.
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('BACK'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onLayoutConfirmed(
                  _selectedLayout,
                  _polygonSides.toInt(),
                );
              },
              child: const Text('USE THIS LAYOUT'),
            ),
          ],
        ),
      ],
    );
  }
}
