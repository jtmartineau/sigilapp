import 'package:flutter/material.dart';

class IncantationStep extends StatefulWidget {
  final Function(String) onIncantationConfirmed;

  const IncantationStep({super.key, required this.onIncantationConfirmed});

  @override
  State<IncantationStep> createState() => _IncantationStepState();
}

class _IncantationStepState extends State<IncantationStep> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your intention',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          maxLength: 128,
          maxLines: 3,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'e.g., I am protected from harm',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _hasText
              ? () => widget.onIncantationConfirmed(_controller.text)
              : null,
          child: const Text('USE THIS INCANTATION'),
        ),
      ],
    );
  }
}
