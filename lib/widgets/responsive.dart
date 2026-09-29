import 'package:flutter/material.dart';

import '../theme.dart';

class Breakpoints {
  Breakpoints._();

  /// NavigationRail instead of NavigationBar.
  static const double rail = 900;

  /// Multi-column layouts (e.g. 3 fare columns).
  static const double wide = 1000;

  static bool isRail(BuildContext c) => MediaQuery.sizeOf(c).width >= rail;
  static bool isWide(BuildContext c) => MediaQuery.sizeOf(c).width >= wide;
}

/// Centres [child] and caps its width at [maxWidth] (default 1100).
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.child,
    this.maxWidth = AppTheme.maxContentWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpace.l),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      );
}
