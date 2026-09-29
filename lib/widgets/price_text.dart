import 'package:flutter/material.dart';

import '../logic/formatters.dart';

/// "₹12,450" with Indian digit grouping.
class PriceText extends StatelessWidget {
  const PriceText(
    this.amount, {
    super.key,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.freeLabel,
  });

  final int amount;
  final TextStyle? style;

  /// e.g. "from ".
  final String prefix;

  /// e.g. " / pax".
  final String suffix;

  /// When set and [amount] is 0, shows this instead (e.g. "Free").
  final String? freeLabel;

  static String format(int amount) => Fmt.inr(amount);

  @override
  Widget build(BuildContext context) {
    final core = (amount == 0 && freeLabel != null) ? freeLabel! : Fmt.inr(amount);
    return Text('$prefix$core$suffix', style: style ?? Theme.of(context).textTheme.titleMedium);
  }
}
