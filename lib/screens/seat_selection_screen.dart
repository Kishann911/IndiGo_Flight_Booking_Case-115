import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/formatters.dart';
import '../logic/pricing.dart';
import '../models/models.dart';
import '../state/booking_store.dart';
import '../theme.dart';
import '../widgets/cabin_map.dart';
import '../widgets/empty_state.dart';
import '../widgets/journey_progress.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';
import 'extras_screen.dart';

/// Step 4: interactive A320neo cabin map for one segment (F3).
class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key, required this.segIndex});

  final int segIndex;

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  int _active = 0;
  Seat? _tapped;

  void _onTap(Seat seat, BookingStore store) {
    final d = store.draft;
    if (d == null || seat.occupied || d.passengers.isEmpty) return;
    final pax = d.passengers[_active.clamp(0, d.passengers.length - 1)];
    store.setSeat(widget.segIndex, pax.id, seat.id);
    final after = store.draft!;
    // Move on to the next passenger without a seat on this segment.
    var next = _active;
    for (var i = 1; i <= after.passengers.length; i++) {
      final j = (_active + i) % after.passengers.length;
      if (after.seatFor(widget.segIndex, after.passengers[j].id) == null) {
        next = j;
        break;
      }
    }
    setState(() {
      _tapped = seat;
      _active = next;
    });
  }

  void _next(BookingStore store, {bool skip = false}) {
    final d = store.draft!;
    if (skip) {
      for (final p in d.passengers) {
        store.setSeat(widget.segIndex, p.id, null);
      }
    }
    final Widget page = widget.segIndex + 1 < d.segmentCount
        ? SeatSelectionScreen(segIndex: widget.segIndex + 1)
        : const ExtrasScreen();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookingStore>();
    final d = store.draft;
    final seg = widget.segIndex;
    if (d == null || seg >= d.segmentCount || d.flights[seg] == null || d.passengers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Choose seats')),
        body: const EmptyState(icon: Icons.event_seat_outlined, title: 'No booking in progress'),
      );
    }
    final flight = d.flights[seg]!;
    final family = d.families[seg]!;
    final theme = Theme.of(context);
    final cabin = store.cabinFor(flight);
    final active = d.passengers[_active.clamp(0, d.passengers.length - 1)];
    final mySeats = d.seats[seg];
    final markers = CabinMap.markersFrom(mySeats, d.passengers);
    final selected = mySeats[active.id];
    final seatTotal = [
      for (final id in mySeats.values) PricingEngine.seatFee(CabinLayout.seatsById[id]!, family),
    ].fold<int>(0, (a, b) => a + b);
    final wide = Breakpoints.isWide(context);

    final panel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Seating for',
          icon: Icons.people_outline,
          child: Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              for (var i = 0; i < d.passengers.length; i++)
                ChoiceChip(
                  key: ValueKey('pax-chip-$i'),
                  selected: d.passengers[i].id == active.id,
                  onSelected: (_) => setState(() => _active = i),
                  avatar: CircleAvatar(child: Text(d.passengers[i].initials, style: theme.textTheme.labelSmall)),
                  label: Text('${d.passengers[i].firstName} · ${mySeats[d.passengers[i].id] ?? 'no seat'}'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.m),
        _SeatInfo(seat: _tapped, family: family),
        const SizedBox(height: AppSpace.m),
        SectionCard(
          title: 'Seat tiers',
          subtitle: 'Fees per passenger, by legroom',
          icon: Icons.info_outline,
          child: CabinMap.legend(family: family),
        ),
      ],
    );

    final map = Center(
      child: CabinMap(
        seats: cabin,
        selected: selected,
        passengerSeats: markers,
        family: family,
        onTap: (s) => _onTap(s, store),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Choose seats · ${flight.from} → ${flight.to}')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: MaxWidthBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const JourneyProgress(step: 4),
                    Text(
                      'Flight ${flight.flightNos} · ${Fmt.weekdayDayMonth(flight.departure)} · ${family.label}'
                      '${d.segmentCount > 1 ? ' · segment ${seg + 1} of ${d.segmentCount}' : ''}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpace.m),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: map),
                          const SizedBox(width: AppSpace.l),
                          SizedBox(width: 380, child: panel),
                        ],
                      )
                    else ...[
                      panel,
                      const SizedBox(height: AppSpace.m),
                      map,
                    ],
                    const SizedBox(height: AppSpace.l),
                  ],
                ),
              ),
            ),
          ),
          Material(
            elevation: 3,
            color: theme.colorScheme.surface,
            child: SafeArea(
              top: false,
              child: MaxWidthBox(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.s),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.m,
                  runSpacing: AppSpace.s,
                  children: [
                    Text('Seat fees this flight: ${Fmt.inr(seatTotal)}',
                        key: const ValueKey('seat-total'), style: theme.textTheme.titleMedium),
                    Wrap(spacing: AppSpace.s, runSpacing: AppSpace.s, children: [
                      TextButton(
                        key: const ValueKey('seat-skip'),
                        onPressed: () => _next(store, skip: true),
                        child: const Text('Skip (auto-assign at check-in)'),
                      ),
                      FilledButton(
                        key: const ValueKey('seat-continue'),
                        onPressed: () => _next(store),
                        child: Text(seg + 1 < d.segmentCount ? 'Next flight' : 'Continue to extras'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatInfo extends StatelessWidget {
  const _SeatInfo({required this.seat, required this.family});

  final Seat? seat;
  final FareFamily family;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = seat;
    if (s == null) {
      return SectionCard(
        title: 'Seat details',
        icon: Icons.event_seat_outlined,
        child: Text('Tap a free seat to see its price and legroom.', style: theme.textTheme.bodyMedium),
      );
    }
    final fee = PricingEngine.seatFee(s, family);
    return SectionCard(
      title: 'Seat ${s.id} · ${s.position}',
      icon: Icons.event_seat,
      trailing: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: AppColors.tier(s.tier), shape: BoxShape.circle),
      ),
      child: Column(
        key: const ValueKey('seat-info'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.tier.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.xs),
          Text('Legroom: ${s.tier.legroom}', key: const ValueKey('seat-legroom'), style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpace.xs),
          Text(fee == 0 ? 'Price: Free with ${family.label}' : 'Price: ${Fmt.inr(fee)}',
              key: const ValueKey('seat-price'), style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
