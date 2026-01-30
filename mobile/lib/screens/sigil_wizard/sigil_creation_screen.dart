import 'package:flutter/material.dart';
import '../../utils/sigil_processor.dart';
import 'incantation_step.dart';
import 'layout_selection_step.dart';
import 'drawing_step.dart';

class SigilCreationScreen extends StatefulWidget {
  const SigilCreationScreen({super.key});

  @override
  State<SigilCreationScreen> createState() => _SigilCreationScreenState();
}

class _SigilCreationScreenState extends State<SigilCreationScreen> {
  int _currentStep = 0;
  String _incantation = '';
  List<String> _consonants = [];

  // Layout State
  String _layoutType = 'Circle'; // 'Circle' or 'Polygon'
  int _polygonSides = 3;

  // Drawing State
  // We'll pass these down to the DrawingStep

  void _processIncantation(String text) {
    setState(() {
      _incantation = text;
    });

    try {
      final result = SigilProcessor.processIncantation(text);

      setState(() {
        _consonants = result;
        _currentStep = 1; // Move to Layout Step
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _onLayoutConfirmed(String type, int sides) {
    setState(() {
      _layoutType = type;
      _polygonSides = sides;
      _currentStep = 2; // Move to Drawing Step
    });
  }

  void _onRetryingLayout() {
    setState(() {
      _currentStep = 1; // Go back to Layout Step from Drawing
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return IncantationStep(onIncantationConfirmed: _processIncantation);
      case 1:
        return LayoutSelectionStep(
          consonants: _consonants,
          onLayoutConfirmed: _onLayoutConfirmed,
        );
      case 2:
        return DrawingStep(
          incantation: _incantation,
          consonants: _consonants,
          layoutType: _layoutType,
          polygonSides: _polygonSides,
          onRetryLayout: _onRetryingLayout,
          onSigilCompleted: () {
            // Handle completion (burning/saving)
            // For now just pop
            Navigator.pop(context);
          },
        );
      default:
        return const Center(child: Text('Unknown Step'));
    }
  }
}
