import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../logic/formatters.dart';
import '../logic/pricing.dart';
import '../models/models.dart';
import '../state/booking_store.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/journey_progress.dart';
import '../widgets/price_text.dart';
import '../widgets/responsive.dart';
import 'flight_detail_screen.dart';

enum _Sort { cheapest, earliest, fastest }

/// F2: flight list for one search segment.
class FlightResultsScreen extends StatefulWidget {
  const FlightResultsScreen({super.key, required this.segIndex});

  final int segIndex;

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

/// Minimum gap between one segment's arrival and the next segment's departure.
const minConnection = Duration(minutes: 60);

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  _Sort _sort = _Sort.earliest;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookingStore>();
    final d = store.draft;
    if (d == null || widget.segIndex >= d.segments.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flights')),
        body: const EmptyState(
          icon: Icons.flight_outlined,
          title: 'No search in progress',
          message: 'Go back and search for flights first.',
        ),
      );
    }
    final seg = d.segments[widget.segIndex];
    final today = store.clock();
    final fares = <String, int>{};
    var flights = SampleData.flightsFor(seg.from, seg.to, seg.date);
    // Later segments must depart at least 60 min after the previous arrival.
    final prev = widget.segIndex > 0 ? d.flights[widget.segIndex - 1] : null;
    final minDeparture = prev?.arrival.add(minConnection);
    if (minDeparture != null) {
      flights = flights.where((f) => !f.departure.isBefore(minDeparture)).toList();
    }
    for (final f in flights) {
      fares[f.id] = PricingEngine.dynamicBaseFare(f, today);
    }
    flights.sort(switch (_sort) {
      _Sort.cheapest => (a, b) => fares[a.id]!.compareTo(fares[b.id]!),
      _Sort.earliest => (a, b) => a.departure.compareTo(b.departure),
      _Sort.fastest => (a, b) => a.totalDuration.compareTo(b.totalDuration),
    });
    final cheapest = fares.values.isEmpty ? 0 : fares.values.reduce((a, b) => a < b ? a : b);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${seg.from} → ${seg.to}'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
        children: [
          MaxWidthBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JourneyProgress(step: 2),
                if (d.segmentCount > 1)
                  Text('Flight ${widget.segIndex + 1} of ${d.segmentCount}',
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                Text(
                  '${SampleData.cityOf(seg.from)} to ${SampleData.cityOf(seg.to)}',
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  '${Fmt.date(seg.date)} · ${d.passengerCount} ${d.passengerCount == 1 ? 'passenger' : 'passengers'} · ${flights.length} flights',
                  style: theme.textTheme.bodyMedium,
                ),
                if (minDeparture != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: Text(
                      'Only flights departing ≥ 60 min after your previous arrival are shown.',
                      key: const ValueKey('chronology-note'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: AppSpace.m),
                Wrap(
                  spacing: AppSpace.s,
                  children: [
                    for (final s in _Sort.values)
                      ChoiceChip(
                        key: ValueKey('sort-${s.name}'),
                        label: Text(switch (s) {
                          _Sort.cheapest => 'Cheapest',
                          _Sort.earliest => 'Earliest',
                          _Sort.fastest => 'Fastest',
                        }),
                        selected: _sort == s,
                        onSelected: (_) => setState(() => _sort = s),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.m),
                if (flights.isEmpty)
                  EmptyState(
                    icon: Icons.flight_outlined,
                    title: 'No flights found',
                    message: minDeparture != null
                        ? 'No flights leave at least 60 min after your previous arrival. '
                            'Go back and try another date for this flight.'
                        : 'Try a different date or route.',
                  ),
                for (final f in flights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.m),
                    child: _FlightCard(
                      flight: f,
                      fare: fares[f.id]!,
                      isCheapest: fares[f.id] == cheapest,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => FlightDetailScreen(segIndex: widget.segIndex, flight: f),
                      )),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({required this.flight, required this.fare, required this.isCheapest, required this.onTap});

  final Flight flight;
  final int fare;
  final bool isCheapest;
  final VoidCallback onTap;

  String get _stopsText {
    if (flight.stops == 0) return 'Non-stop';
    final n = flight.stops;
    final via = flight.viaAirports.join(', ');
    final lay = flight.layovers.map(Fmt.duration).join(', ');
    return '$n stop${n > 1 ? 's' : ''} via $via · $lay layover';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final times = Row(
      children: [
        _endpoint(theme, Fmt.time(flight.departure), flight.from, CrossAxisAlignment.start),
        Expanded(
          child: Column(
            children: [
              Text(Fmt.duration(flight.totalDuration), style: theme.textTheme.labelMedium),
              Row(
                children: [
                  Expanded(child: Divider(color: scheme.outlineVariant)),
                  Icon(Icons.flight, size: 16, color: scheme.primary),
                  Expanded(child: Divider(color: scheme.outlineVariant)),
                ],
              ),
              Text(
                _stopsText,
                key: ValueKey('stops-${flight.id}'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: flight.stops == 0 ? AppColors.success : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _endpoint(theme, Fmt.time(flight.arrival), flight.to, CrossAxisAlignment.end),
      ],
    );
    final price = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('from', style: theme.textTheme.bodySmall),
        PriceText(fare, style: theme.textTheme.titleLarge?.copyWith(color: scheme.primary)),
        if (isCheapest)
          Text('Lowest fare', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.success)),
      ],
    );
    return Card(
      key: ValueKey('flight-${flight.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.l),
          child: LayoutBuilder(builder: (context, c) {
            final info = Row(
              children: [
                Icon(Icons.confirmation_number_outlined, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpace.xs),
                Expanded(child: Text(flight.flightNos, style: theme.textTheme.bodySmall)),
              ],
            );
            if (c.maxWidth >= 640) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [times, const SizedBox(height: AppSpace.s), info],
                    ),
                  ),
                  const SizedBox(width: AppSpace.xl),
                  price,
                  const Icon(Icons.chevron_right),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                times,
                const SizedBox(height: AppSpace.s),
                Row(
                  children: [
                    Expanded(child: info),
                    price,
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _endpoint(ThemeData theme, String time, String code, CrossAxisAlignment align) => Column(
        crossAxisAlignment: align,
        children: [
          Text(time, style: theme.textTheme.titleLarge),
          Text(code, style: theme.textTheme.bodySmall),
        ],
      );
}
