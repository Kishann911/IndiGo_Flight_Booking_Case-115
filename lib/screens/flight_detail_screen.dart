import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../logic/formatters.dart';
import '../logic/pricing.dart';
import '../models/models.dart';
import '../state/booking_store.dart';
import '../theme.dart';
import '../widgets/fare_family_card.dart';
import '../widgets/journey_progress.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';
import 'flight_results_screen.dart';
import 'passenger_details_screen.dart';

/// F4 + Product Building: flight details and Lite / Classic / Flex comparison.
class FlightDetailScreen extends StatelessWidget {
  const FlightDetailScreen({super.key, required this.segIndex, required this.flight});

  final int segIndex;
  final Flight flight;

  void _select(BuildContext context, FareFamily family) {
    final store = context.read<BookingStore>();
    store.chooseFlight(segIndex, flight, family);
    final next = store.draft?.nextUnchosenSegment;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => next != null ? FlightResultsScreen(segIndex: next) : const PassengerDetailsScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookingStore>();
    final theme = Theme.of(context);
    final d = store.draft;
    final base = PricingEngine.dynamicBaseFare(flight, store.clock());
    final chosen = d != null && segIndex < d.segmentCount && d.flights[segIndex] == flight ? d.families[segIndex] : null;
    final meals = SampleData.meals.take(6).toList();
    final wide = Breakpoints.isWide(context);

    Widget card(FareFamily f, {double? width}) => FareFamilyCard(
          family: f,
          price: base + PricingEngine.familyCharge(f),
          selected: chosen == f,
          width: width,
          onSelect: () => _select(context, f),
        );

    return Scaffold(
      appBar: AppBar(title: Text('${flight.from} → ${flight.to}')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
        children: [
          MaxWidthBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JourneyProgress(step: 3),
                const SizedBox(height: AppSpace.s),
                SectionCard(
                  title: 'Flight details',
                  subtitle: '${Fmt.date(flight.departure)} · ${flight.flightNos}',
                  icon: Icons.flight_takeoff,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          key: const ValueKey('total-duration'),
                          avatar: const Icon(Icons.timer_outlined, size: 16),
                          label: Text('Total duration ${Fmt.duration(flight.totalDuration)}'),
                        ),
                      ),
                      for (var i = 0; i < flight.legs.length; i++) ...[
                        if (i > 0) _layover(context, flight.layovers[i - 1], flight.legs[i].from),
                        _legTile(context, flight.legs[i]),
                      ],
                      const SizedBox(height: AppSpace.s),
                      Text(
                        flight.stops == 0
                            ? 'Non-stop flight.'
                            : '${flight.stops} stop${flight.stops > 1 ? 's' : ''}, total layover ${Fmt.duration(flight.layovers.fold(Duration.zero, (a, b) => a + b))}.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Meals on board',
                  subtitle: 'Buy on board, or pre-order on the Extras step',
                  icon: Icons.restaurant_outlined,
                  child: Wrap(
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.s,
                    children: [
                      for (final m in meals)
                        Chip(
                          avatar: Icon(m.isVeg ? Icons.eco_outlined : Icons.set_meal_outlined, size: 16),
                          label: Text('${m.name} · ${m.cuisine}'),
                        ),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Baggage allowance',
                  icon: Icons.luggage_outlined,
                  child: Column(
                    children: [
                      for (final info in FareFamilyInfo.all)
                        ListTile(
                          key: ValueKey('baggage-${info.family.name}'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.work_outline, color: AppColors.fare(info.family)),
                          title: Text(info.name),
                          subtitle: Text(info.baggageText),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s),
                Text('Choose your fare', style: theme.textTheme.headlineSmall),
                Text(
                  'Prices per passenger for this flight. Dynamic fare ${Fmt.inr(base)} plus the fare family charge.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpace.s),
                _BookingWindowInfo(days: PricingEngine.daysBetween(store.clock(), flight.departure)),
                const SizedBox(height: AppSpace.m),
                if (wide)
                  Row(
                    key: const ValueKey('fare-columns'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final f in FareFamily.values) ...[
                        Expanded(child: card(f)),
                        if (f != FareFamily.flex) const SizedBox(width: AppSpace.m),
                      ],
                    ],
                  )
                else
                  SingleChildScrollView(
                    key: const ValueKey('fare-columns'),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final f in FareFamily.values) ...[
                          card(f, width: 264),
                          if (f != FareFamily.flex) const SizedBox(width: AppSpace.m),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpace.m),
                Card(
                  color: theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.m),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: theme.colorScheme.onSecondaryContainer),
                        const SizedBox(width: AppSpace.s),
                        Expanded(
                          child: Text(
                            'Add-on upgrades are available on the Extras step: extra baggage, priority boarding and lounge access.',
                            key: const ValueKey('addon-note'),
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legTile(BuildContext context, FlightLeg leg) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
              Container(width: 2, height: 44, color: theme.colorScheme.outlineVariant),
              Icon(Icons.circle_outlined, size: 10, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${Fmt.time(leg.departure)}  ${SampleData.cityOf(leg.from)} (${leg.from})',
                    style: theme.textTheme.titleMedium),
                Text('${leg.flightNo} · ${leg.aircraft} · ${Fmt.duration(leg.duration)}',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpace.xs),
                Text('${Fmt.time(leg.arrival)}  ${SampleData.cityOf(leg.to)} (${leg.to})',
                    style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _layover(BuildContext context, Duration d, String at) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('layover-callout'),
      margin: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      padding: const EdgeInsets.all(AppSpace.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_bottom, size: 18, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: Text(
              'Layover ${Fmt.duration(d)} in ${SampleData.cityOf(at)} ($at)',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains the advance-purchase multiplier applied to this flight's fare.
class _BookingWindowInfo extends StatelessWidget {
  const _BookingWindowInfo({required this.days});

  final int days;

  static const _table = [
    ('30 days or more', '×0.85'),
    ('15–29 days', '×0.95'),
    ('7–14 days', '×1.00'),
    ('3–6 days', '×1.15'),
    ('0–2 days', '×1.30'),
  ];

  String get _line {
    final m = PricingEngine.bookingWindowMultiplier(days);
    final pct = ((m - 1).abs() * 100).round();
    final ahead = 'Booked $days ${days == 1 ? 'day' : 'days'} ahead';
    if (m < 1) return '$ahead · $pct% advance-purchase discount applied';
    if (m > 1) return '$ahead · $pct% late-booking surcharge';
    return '$ahead · standard fare, no adjustment';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = PricingEngine.bookingWindowMultiplier(days);
    final color = m < 1 ? AppColors.success : (m > 1 ? AppColors.warning : theme.colorScheme.onSurfaceVariant);
    return Card(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('pricing-table-toggle'),
          leading: Icon(m < 1 ? Icons.trending_down : (m > 1 ? Icons.trending_up : Icons.trending_flat), color: color),
          title: Text(_line, key: const ValueKey('booking-window-line'), style: theme.textTheme.titleSmall),
          subtitle: const Text('Tap for the full booking-window table'),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, AppSpace.m),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (range, mult) in _table)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('$range before departure  $mult', style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}
