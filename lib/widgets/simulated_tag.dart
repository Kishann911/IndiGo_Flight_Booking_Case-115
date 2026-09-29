import 'package:flutter/material.dart';

/// Small "(simulated)" pill for real-time / push / RFID features.
class SimulatedTag extends StatelessWidget {
  const SimulatedTag({super.key, this.label = 'simulated'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: s.tertiaryContainer, borderRadius: BorderRadius.circular(999)),
      child: Text('($label)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: s.onTertiaryContainer)),
    );
  }
}
