import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/formatters.dart';
import '../logic/pricing.dart';
import '../state/booking_store.dart';
import '../theme.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';

/// F1: lowest-fare calendar, 60 days from today. Pops with the chosen date.
class FareCalendarScreen extends StatefulWidget {
  const FareCalendarScreen({super.key, required this.from, required this.to, required this.initialDate});

  final String from;
  final String to;
  final DateTime initialDate;

  @override
  State<FareCalendarScreen> createState() => _FareCalendarScreenState();
}

class _FareCalendarScreenState extends State<FareCalendarScreen> {
  static const _days = 60;

  late final DateTime _today;
  late final Map<DateTime, int> _fares;
  late DateTime _month; // first of the visible month

  @override
  void initState() {
    super.initState();
    final n = context.read<BookingStore>().clock();
    _today = DateTime(n.year, n.month, n.day);
    _fares = {};
    for (var i = 0; i < _days; i++) {
      final d = DateTime(_today.year, _today.month, _today.day + i);
      _fares[d] = PricingEngine.lowestFareForDay(widget.from, widget.to, d, n);
    }
    final init = widget.initialDate;
    final start = _fares.containsKey(DateTime(init.year, init.month, init.day)) ? init : _today;
    _month = DateTime(start.year, start.month);
  }

  DateTime get _firstMonth => DateTime(_today.year, _today.month);
  DateTime get _lastMonth {
    final last = DateTime(_today.year, _today.month, _today.day + _days - 1);
    return DateTime(last.year, last.month);
  }

  void _shift(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inMonth = _fares.entries.where((e) => e.key.year == _month.year && e.key.month == _month.month).toList();
    final cheapest = inMonth.isEmpty ? 0 : inMonth.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final initial = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);

    final offset = DateTime(_month.year, _month.month, 1).weekday - 1; // Monday first
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((offset + daysInMonth) / 7).ceil();

    return Scaffold(
      appBar: AppBar(title: Text('Fares ${widget.from} → ${widget.to}')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
        children: [
          MaxWidthBox(
            maxWidth: 640,
            child: SectionCard(
              title: 'Lowest fare per day',
              subtitle: 'Per passenger, Lite fare. Next 60 days. Tap a day to select it.\n'
                  'Fares include booking-window pricing — book early to save',
              icon: Icons.calendar_month,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const ValueKey('cal-prev'),
                        tooltip: 'Previous month',
                        onPressed: _month.isAfter(_firstMonth) ? () => _shift(-1) : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(Fmt.monthYear(_month),
                            key: const ValueKey('cal-month'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium),
                      ),
                      IconButton(
                        key: const ValueKey('cal-next'),
                        tooltip: 'Next month',
                        onPressed: _month.isBefore(_lastMonth) ? () => _shift(1) : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      for (var w = 1; w <= 7; w++)
                        Expanded(
                          child: Center(child: Text(Fmt.weekdayShort(w), style: theme.textTheme.labelSmall)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  for (var r = 0; r < rows; r++)
                    Row(
                      children: [
                        for (var c = 0; c < 7; c++)
                          Expanded(child: _cell(context, r * 7 + c - offset + 1, daysInMonth, cheapest, initial)),
                      ],
                    ),
                  const SizedBox(height: AppSpace.m),
                  Wrap(
                    spacing: AppSpace.l,
                    runSpacing: AppSpace.xs,
                    children: [
                      _legend(context, scheme.tertiaryContainer, 'Cheapest day(s) this month'),
                      _legend(context, scheme.primary, 'Selected date'),
                      _legend(context, scheme.surfaceContainerHighest, 'Not available'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: AppSpace.xs),
          Flexible(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      );

  Widget _cell(BuildContext context, int day, int daysInMonth, int cheapest, DateTime initial) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 60);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = DateTime(_month.year, _month.month, day);
    final fare = _fares[date];
    final available = fare != null;
    final isCheapest = available && fare == cheapest;
    final selected = date == initial;
    final Color bg = selected
        ? scheme.primary
        : isCheapest
            ? scheme.tertiaryContainer
            : available
                ? scheme.surface
                : scheme.surfaceContainerHighest;
    final Color fg = selected
        ? scheme.onPrimary
        : isCheapest
            ? scheme.onTertiaryContainer
            : available
                ? scheme.onSurface
                : scheme.outline;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Semantics(
        button: available,
        excludeSemantics: true,
        onTap: available ? () => Navigator.of(context).pop(date) : null,
        label: available
            ? '${Fmt.date(date)}, lowest fare ${Fmt.inr(fare)}${isCheapest ? ', cheapest of the month' : ''}'
            : '${Fmt.date(date)}, not available',
        child: ExcludeSemantics(
          child: Material(
            key: ValueKey('cal-day-${date.month}-$day'),
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: isCheapest ? scheme.tertiary : scheme.outlineVariant),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: available ? () => Navigator.of(context).pop(date) : null,
              child: SizedBox(
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day', style: theme.textTheme.labelLarge?.copyWith(color: fg)),
                    if (available)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Fmt.inr(fare),
                            key: ValueKey('cal-fare-${date.month}-$day'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: fg,
                              fontWeight: isCheapest ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
