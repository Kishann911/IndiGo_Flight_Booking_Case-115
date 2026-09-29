import 'package:flutter/material.dart';

import '../models/fare_family.dart';
import '../theme.dart';
import 'price_text.dart';

/// One column of the Lite / Classic / Flex comparison.
/// Keys: `fare-card-<family>` on the card, `select-<family>` on the button.
class FareFamilyCard extends StatelessWidget {
  const FareFamilyCard({
    super.key,
    required this.family,
    required this.price,
    this.selected = false,
    this.onSelect,
    this.width,
    this.priceCaption = 'per passenger',
  });

  final FareFamily family;

  /// Dynamic base fare + family charge, per passenger.
  final int price;
  final bool selected;
  final VoidCallback? onSelect;

  /// Fixed width (for the phone horizontal scroll row); null expands.
  final double? width;
  final String priceCaption;

  static IconData _iconFor(int i) => const [
        Icons.luggage_outlined,
        Icons.restaurant_outlined,
        Icons.event_repeat_outlined,
        Icons.money_off_csred_outlined,
        Icons.event_seat_outlined,
      ][i];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = family.info;
    final color = AppColors.fare(family);
    final card = Card(
      key: ValueKey('fare-card-${family.name}'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: BorderSide(color: selected ? color : theme.colorScheme.outlineVariant, width: selected ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.all(AppSpace.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                Text(info.tagline, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PriceText(price, style: theme.textTheme.headlineSmall?.copyWith(color: color)),
                Text(priceCaption, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpace.m),
                for (var i = 0; i < info.features.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_iconFor(i), size: 18, color: color),
                        const SizedBox(width: AppSpace.s),
                        Expanded(child: Text(info.features[i], style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpace.s),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: ValueKey('select-${family.name}'),
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: onSelect,
                    child: Text(selected ? 'Selected' : 'Select ${info.name}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }
}
