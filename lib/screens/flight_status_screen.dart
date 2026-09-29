import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../logic/formatters.dart';
import '../models/models.dart';
import '../state/booking_store.dart';
import '../state/flight_status_service.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/notification_bell.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';
import '../widgets/simulated_tag.dart';
import 'baggage_screen.dart';

/// A flight leg the user can track (from a booking or from a search).
class _TrackedLeg {
  const _TrackedLeg(this.leg, {this.pnr});

  final FlightLeg leg;
  final String? pnr;

  String get key => leg.flightNo;
}

/// F7: flight status tracker (simulated real-time).
class FlightStatusScreen extends StatefulWidget {
  const FlightStatusScreen({super.key});

  @override
  State<FlightStatusScreen> createState() => _FlightStatusScreenState();
}

class _FlightStatusScreenState extends State<FlightStatusScreen> {
  final _search = TextEditingController();
  _TrackedLeg? _selected;
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_TrackedLeg> _myLegs(BookingStore store) => [
        for (final b in store.bookings.where((b) => !b.isCancelled))
          for (final s in b.segments)
            for (final l in s.flight.legs) _TrackedLeg(l, pnr: b.pnr),
      ];

  static String _norm(String s) => s.toUpperCase().replaceAll(RegExp(r'\s+'), '');

  void _doSearch(BookingStore store) {
    final q = _norm(_search.text);
    if (q.isEmpty) return;
    final wanted = RegExp(r'^\d+$').hasMatch(q) ? '6E$q' : q;
    for (final l in _myLegs(store)) {
      if (_norm(l.leg.flightNo) == wanted) {
        setState(() {
          _selected = l;
          _error = null;
        });
        return;
      }
    }
    // Otherwise look through today's and tomorrow's simulated timetable.
    final today = store.clock();
    for (var d = 0; d < 2; d++) {
      final day = DateTime(today.year, today.month, today.day + d);
      for (final a in SampleData.airports) {
        for (final b in SampleData.airports) {
          if (a.code == b.code) continue;
          for (final f in SampleData.flightsFor(a.code, b.code, day)) {
            for (final l in f.legs) {
              if (_norm(l.flightNo) == wanted) {
                setState(() {
                  _selected = _TrackedLeg(l);
                  _error = null;
                });
                return;
              }
            }
          }
        }
      }
    }
    setState(() => _error = 'No flight "${_search.text.trim()}" found in the simulated timetable.');
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingStore>();
    final service = context.watch<FlightStatusService>();
    final mine = _myLegs(bookings);
    final current = _selected ?? mine.firstOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight status'),
        actions: const [AppBarActions()],
      ),
      body: MaxWidthBox(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.m),
          children: [
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Live flight tracker', style: theme.textTheme.titleLarge),
                const SimulatedTag(label: 'simulated real-time'),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            SectionCard(
              title: 'Find a flight',
              icon: Icons.search,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('flight-search'),
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _doSearch(bookings),
                          decoration: const InputDecoration(
                            labelText: 'Flight number',
                            hintText: 'e.g. 6E 2175',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s),
                      FilledButton(
                        key: const ValueKey('flight-search-go'),
                        onPressed: () => _doSearch(bookings),
                        child: const Text('Track'),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.s),
                      child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    ),
                  if (mine.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.m),
                    Text('From my bookings', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpace.xs),
                    Wrap(
                      spacing: AppSpace.s,
                      runSpacing: AppSpace.xs,
                      children: [
                        for (final l in mine)
                          ChoiceChip(
                            key: ValueKey('my-flight-${l.leg.flightNo}'),
                            label: Text('${l.leg.flightNo} · ${l.leg.from}→${l.leg.to}'),
                            selected: current?.key == l.key,
                            onSelected: (_) => setState(() {
                              _selected = l;
                              _error = null;
                            }),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.m),
            if (current == null)
              const SizedBox(
                height: 260,
                child: EmptyState(
                  icon: Icons.radar_outlined,
                  title: 'No flight selected',
                  message: 'Search a flight number, or book a trip to track it here.',
                ),
              )
            else
              _LiveCard(leg: current, service: service),
          ],
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.leg, required this.service});

  final _TrackedLeg leg;
  final FlightStatusService service;

  @override
  Widget build(BuildContext context) {
    final l = leg.leg;
    final t = service.trackingFor(l.flightNo, l.departure, l.arrival);
    final events = service.eventsFor(l.flightNo);
    final theme = Theme.of(context);
    final color = AppColors.status(t.status);
    final delayed = t.delayMinutes > 0;

    final live = SectionCard(
      title: '${l.flightNo} · ${SampleData.cityOf(l.from)} → ${SampleData.cityOf(l.to)}',
      subtitle: '${Fmt.date(l.departure)} · ${l.aircraft}',
      icon: Icons.flight,
      trailing: Chip(
        key: const ValueKey('status-chip'),
        label: Text(t.status.label),
        avatar: Icon(Icons.circle, size: 12, color: color),
        side: BorderSide(color: color),
        visualDensity: VisualDensity.compact,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpace.xl,
            runSpacing: AppSpace.m,
            children: [
              _fact(context, 'Gate', t.gate, key: const ValueKey('gate-value')),
              _fact(context, 'Delay', delayed ? '+${t.delayMinutes} min' : 'On time',
                  key: const ValueKey('delay-value'), color: delayed ? AppColors.warning : AppColors.success),
              _fact(context, 'Departure', Fmt.time(t.estimatedDeparture),
                  note: delayed ? 'Scheduled ${Fmt.time(t.scheduledDeparture)}' : 'Scheduled'),
              _fact(context, 'Arrival', Fmt.time(t.estimatedArrival),
                  note: delayed ? 'Scheduled ${Fmt.time(t.scheduledArrival)}' : 'Scheduled'),
            ],
          ),
          const SizedBox(height: AppSpace.l),
          Row(
            children: [
              Text(l.from, style: theme.textTheme.labelLarge),
              const SizedBox(width: AppSpace.s),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    const iconSize = 24.0;
                    final left = (c.maxWidth - iconSize) * t.progress.clamp(0.0, 1.0);
                    return SizedBox(
                      height: iconSize,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          LinearProgressIndicator(
                            key: const ValueKey('flight-progress'),
                            value: t.progress.clamp(0.0, 1.0),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          Positioned(
                            left: left,
                            child: Transform.rotate(
                              angle: 1.5708,
                              child: Icon(Icons.flight, size: iconSize, color: color),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpace.s),
              Text(l.to, style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text('${(t.progress * 100).round()}% of the journey completed (simulated)',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpace.l),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              FilledButton.tonalIcon(
                key: const ValueKey('simulate-delay'),
                onPressed: () => service.simulateDelay(l.flightNo, 30),
                icon: const Icon(Icons.schedule),
                label: const Text('Simulate delay'),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('simulate-gate'),
                onPressed: () => service.simulateGateChange(l.flightNo, service.nextGate(l.flightNo)),
                icon: const Icon(Icons.door_front_door_outlined),
                label: const Text('Simulate gate change'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('track-bags'),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BaggageScreen())),
                icon: const Icon(Icons.luggage_outlined),
                label: const Text('Track my bags'),
              ),
            ],
          ),
        ],
      ),
    );

    final timeline = SectionCard(
      title: 'Event timeline',
      subtitle: 'Simulated updates, oldest first',
      icon: Icons.timeline,
      child: Column(
        children: [
          for (final e in events)
            ListTile(
              key: ValueKey('event-${events.indexOf(e)}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                switch (e.kind) {
                  'delay' => Icons.schedule,
                  'gate' => Icons.door_front_door_outlined,
                  _ => Icons.flag_outlined,
                },
                color: switch (e.kind) {
                  'delay' => AppColors.warning,
                  _ => theme.colorScheme.primary,
                },
              ),
              title: Text(e.text),
              subtitle: Text(Fmt.time(e.at)),
            ),
        ],
      ),
    );

    if (Breakpoints.isWide(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: live),
          const SizedBox(width: AppSpace.l),
          Expanded(child: timeline),
        ],
      );
    }
    return Column(children: [live, const SizedBox(height: AppSpace.m), timeline]);
  }

  Widget _fact(BuildContext context, String label, String value, {Key? key, String? note, Color? color}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, key: key, style: theme.textTheme.titleLarge?.copyWith(color: color)),
        if (note != null) Text(note, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
