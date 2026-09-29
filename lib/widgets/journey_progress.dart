import 'package:flutter/material.dart';

import '../theme.dart';

/// "STEP n OF 6 · Search → Flights → Fare → Seats → Extras → Summary".
/// [step] is 1-based: 1 Search, 2 Flights, 3 Fare, 4 Seats, 5 Extras, 6 Summary.
class JourneyProgress extends StatelessWidget {
  const JourneyProgress({super.key, required this.step}) : assert(step >= 1 && step <= 6);

  final int step;

  static const steps = ['Search', 'Flights', 'Fare', 'Seats', 'Extras', 'Summary'];

  static String labelFor(int step) => 'STEP $step OF 6 · ${steps.join(' → ')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Semantics(
      label: labelFor(step),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 2,
                children: [
                  Text('STEP $step OF 6',
                      style: theme.textTheme.labelMedium?.copyWith(color: s.primary, fontWeight: FontWeight.w800)),
                  Text('·', style: theme.textTheme.labelMedium),
                  for (var i = 0; i < steps.length; i++) ...[
                    if (i > 0) Text('→', style: theme.textTheme.labelSmall?.copyWith(color: s.outline)),
                    Text(
                      steps[i],
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: i + 1 == step ? s.primary : (i + 1 < step ? s.onSurface : s.onSurfaceVariant),
                        fontWeight: i + 1 == step ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: step / 6, minHeight: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
