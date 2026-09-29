import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/sample_data.dart';
import '../logic/checkin_rules.dart';
import '../logic/formatters.dart';
import '../models/models.dart';
import '../state/baggage_service.dart';
import '../state/booking_store.dart';
import '../state/flight_status_service.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import 'baggage_screen.dart';

/// F6: mobile boarding pass with a BCBP-like QR code.
class BoardingPassScreen extends StatefulWidget {
  const BoardingPassScreen({super.key, required this.pnr, required this.segIndex, required this.passengerId});

  final String pnr;
  final int segIndex;
  final String passengerId;

  @override
  State<BoardingPassScreen> createState() => _BoardingPassScreenState();
}

class _BoardingPassScreenState extends State<BoardingPassScreen> {
  late String _pid = widget.passengerId;
  int _leg = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookingStore>();
    final booking = store.byPnr(widget.pnr);
    final appBar = AppBar(title: const Text('Boarding pass'));
    if (booking == null || widget.segIndex < 0 || widget.segIndex >= booking.segments.length) {
      return Scaffold(
        appBar: appBar,
        body: const EmptyState(icon: Icons.airplane_ticket_outlined, title: 'Boarding pass not found'),
      );
    }
    final seg = booking.segments[widget.segIndex];
    final pax = booking.passengerById(_pid) ?? booking.passengers.first;
    final legs = seg.flight.legs;
    final leg = legs[_leg.clamp(0, legs.length - 1)];
    final theme = Theme.of(context);

    Widget body;
    if (!booking.isCheckedIn(widget.segIndex, pax.id)) {
      body = SizedBox(
        height: 320,
        child: EmptyState(
          icon: Icons.how_to_reg_outlined,
          title: '${pax.fullName} is not checked in',
          message: 'Complete web check-in to get a boarding pass.',
          action: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
        ),
      );
    } else {
      final seatId = seg.seats[pax.id] ?? '—';
      final priority = booking.addOns.contains(AddOnType.priorityBoarding);
      final zone = CheckInRules.boardingZone(priority, seatId);
      final index = booking.passengers.indexWhere((p) => p.id == pax.id);
      final payload = CheckInRules.bcbpPayload(
        passenger: pax,
        pnr: booking.pnr,
        leg: leg,
        seatId: seatId,
        sequence: index + 1,
      );
      final tracking =
          context.watch<FlightStatusService>().trackingFor(leg.flightNo, leg.departure, leg.arrival);
      final hasBags = context.read<BaggageService>().ensureBagsForBooking(booking).any((b) => b.passengerId == pax.id);
      final boarding = CheckInRules.boardingTime(tracking.estimatedDeparture);
      body = _Pass(
        pax: pax,
        booking: booking,
        family: seg.family,
        leg: leg,
        seatId: seatId,
        zone: zone,
        priority: priority,
        gate: tracking.gate,
        boarding: boarding,
        departure: tracking.estimatedDeparture,
        delayMinutes: tracking.delayMinutes,
        payload: payload,
      );
      if (hasBags) {
        body = Column(
          children: [
            body,
            const SizedBox(height: AppSpace.m),
            OutlinedButton.icon(
              key: const ValueKey('pass-track-bags'),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BaggageScreen())),
              icon: const Icon(Icons.luggage_outlined),
              label: const Text('Track my bags'),
            ),
          ],
        );
      }
    }

    return Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (booking.passengers.length > 1) ...[
                  Text('Passenger', style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpace.xs),
                  Wrap(
                    spacing: AppSpace.s,
                    children: [
                      for (final p in booking.passengers)
                        ChoiceChip(
                          key: ValueKey('pass-pax-${p.id}'),
                          label: Text(p.fullName),
                          selected: p.id == pax.id,
                          onSelected: (_) => setState(() => _pid = p.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.m),
                ],
                if (legs.length > 1) ...[
                  Wrap(
                    spacing: AppSpace.s,
                    children: [
                      for (var i = 0; i < legs.length; i++)
                        ChoiceChip(
                          key: ValueKey('pass-leg-$i'),
                          label: Text('${legs[i].from} → ${legs[i].to}'),
                          selected: i == _leg,
                          onSelected: (_) => setState(() => _leg = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.m),
                ],
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pass extends StatelessWidget {
  const _Pass({
    required this.pax,
    required this.booking,
    required this.family,
    required this.leg,
    required this.seatId,
    required this.zone,
    required this.priority,
    required this.gate,
    required this.boarding,
    required this.departure,
    required this.delayMinutes,
    required this.payload,
  });

  final Passenger pax;
  final Booking booking;
  final FareFamily family;
  final FlightLeg leg;
  final String seatId;
  final int zone;
  final bool priority;
  final String gate;
  final DateTime boarding;
  final DateTime departure;
  final int delayMinutes;
  final String payload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget cell(String label, String value, {Key? key, bool big = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            Text(value, key: key, style: big ? theme.textTheme.titleLarge : theme.textTheme.titleMedium),
          ],
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: scheme.primary,
            padding: const EdgeInsets.all(AppSpace.l),
            child: Row(
              children: [
                Icon(Icons.flight_takeoff, color: scheme.onPrimary),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: Text('Boarding pass',
                      style: theme.textTheme.titleMedium?.copyWith(color: scheme.onPrimary)),
                ),
                Text(family.label, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(pax.fullName.toUpperCase(), key: const ValueKey('pass-name'), style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpace.m),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(leg.from, style: theme.textTheme.displaySmall),
                          Text(SampleData.cityOf(leg.from), style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Icon(Icons.flight, color: scheme.primary),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(leg.to, style: theme.textTheme.displaySmall),
                          Text(SampleData.cityOf(leg.to), style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpace.xl),
                Wrap(
                  spacing: AppSpace.xl,
                  runSpacing: AppSpace.m,
                  children: [
                    cell('Flight', leg.flightNo),
                    cell('Date', Fmt.date(leg.departure)),
                    cell('PNR', booking.pnr, key: const ValueKey('pass-pnr')),
                    cell('Departs', Fmt.time(departure) + (delayMinutes > 0 ? ' (+$delayMinutes m)' : '')),
                    cell('Boarding', Fmt.time(boarding), key: const ValueKey('pass-boarding')),
                    cell('Gate', gate, key: const ValueKey('pass-gate')),
                    cell('Seat', seatId, key: const ValueKey('pass-seat'), big: true),
                    cell('Zone', '$zone${priority ? ' · Priority' : ''}', key: const ValueKey('pass-zone')),
                  ],
                ),
                const SizedBox(height: AppSpace.l),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.m),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: QrImageView(
                      key: const ValueKey('boarding-qr'),
                      data: payload,
                      size: 200,
                      backgroundColor: Colors.white,
                      semanticsLabel: 'Boarding pass QR code',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s),
                Text(payload,
                    key: const ValueKey('pass-payload'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                const SizedBox(height: AppSpace.xs),
                Text('Gate and times update live (simulated). Demo pass — not valid for travel.',
                    textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
