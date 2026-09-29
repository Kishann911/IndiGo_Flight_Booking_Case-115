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
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';
import 'booking_confirmation_screen.dart';

/// Step 6 (F11): itinerary, fare breakdown, cancellation/change policy with a
/// worked refund example. [TripSummaryScreen.forBooking] is the read-only view
/// of an existing booking, with Cancel booking.
class TripSummaryScreen extends StatelessWidget {
  /// Draft mode (booking flow step 6).
  const TripSummaryScreen({super.key}) : pnr = null;

  /// Read-only mode for an existing booking (from My Trips), with Cancel.
  const TripSummaryScreen.forBooking({super.key, required String this.pnr});

  /// null = draft mode.
  final String? pnr;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookingStore>();
    final readOnly = pnr != null;
    final title = readOnly ? 'Trip $pnr' : 'Trip summary';

    late final List<BookedSegment> segments;
    late final List<Passenger> passengers;
    late final Set<AddOnType> addOns;
    late final FareBreakdown fare;
    Booking? booking;
    if (readOnly) {
      booking = store.byPnr(pnr!);
      if (booking == null) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const EmptyState(icon: Icons.search_off, title: 'Booking not found'),
        );
      }
      segments = booking.segments;
      passengers = booking.passengers;
      addOns = booking.addOns;
      fare = booking.fare;
    } else {
      final d = store.draft;
      if (d == null || !d.isComplete) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const EmptyState(icon: Icons.receipt_long_outlined, title: 'No booking in progress'),
        );
      }
      segments = d.bookedSegments;
      passengers = d.passengers;
      addOns = d.addOns;
      fare = store.draftQuote;
    }

    // A booking to run the refund rule on (the real one, or the draft as if booked now).
    final subject = booking ??
        Booking(pnr: 'DRAFT0', bookedAt: store.clock(), passengers: passengers, segments: segments, addOns: addOns, fare: fare);
    final now = store.clock();
    final blockedReason = booking == null ? null : store.cancelBlockedReason(booking.pnr);

    final itinerary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          _SegmentCard(index: i, segment: segments[i], passengers: passengers, total: segments.length),
          const SizedBox(height: AppSpace.m),
        ],
        SectionCard(
          title: 'Passengers & add-ons',
          icon: Icons.people_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in passengers)
                Text('${p.fullName} · age ${p.age}${p.frequentFlyerNo != null ? ' · FF ${p.frequentFlyerNo}' : ''}'),
              const SizedBox(height: AppSpace.s),
              Text(
                addOns.isEmpty ? 'No add-ons selected' : 'Add-ons: ${addOns.map((a) => a.label).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FareCard(fare: fare, passengers: passengers.length, segments: segments.length),
        const SizedBox(height: AppSpace.m),
        _PolicyCard(segments: segments, subject: subject, now: now, real: readOnly),
        const SizedBox(height: AppSpace.m),
        if (!readOnly) ...[
          Text('Demo booking — no payment is taken.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpace.s),
          FilledButton.icon(
            key: const ValueKey('confirm-booking'),
            onPressed: () {
              final b = context.read<BookingStore>().confirmDraft();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => BookingConfirmationScreen(pnr: b.pnr)),
                (r) => r.isFirst,
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Confirm booking (demo — no payment)'),
          ),
        ] else if (!booking!.isCancelled) ...[
          OutlinedButton.icon(
            key: const ValueKey('cancel-booking'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: blockedReason == null ? () => _confirmCancel(context, booking!.pnr) : null,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel booking'),
          ),
          if (blockedReason != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s),
              child: Text(blockedReason, key: const ValueKey('cancel-blocked'), style: Theme.of(context).textTheme.bodySmall),
            ),
        ] else
          const _CancelledNote(),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.xl),
        children: [
          MaxWidthBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!readOnly) const JourneyProgress(step: 6) else const SizedBox(height: AppSpace.m),
                if (Breakpoints.isWide(context))
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: itinerary),
                    const SizedBox(width: AppSpace.l),
                    SizedBox(width: 440, child: side),
                  ])
                else ...[itinerary, const SizedBox(height: AppSpace.m), side],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, String pnr) async {
    final store = context.read<BookingStore>();
    final refund = store.refundQuote(pnr);
    final b = store.byPnr(pnr)!;
    final departedNoRefund = refund == 0 &&
        store.clock().isAfter(b.departure) &&
        !b.segments.every((s) => s.family == FareFamily.flex);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel booking $pnr?'),
        content: Text('Refund if you cancel now: ${Fmt.inr(refund)}\n\n'
            '${departedNoRefund ? 'This flight has already departed: Lite and Classic fares are not refunded after departure.\n\n' : ''}'
            'Demo only: no money moves.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep booking')),
          FilledButton(
              key: const ValueKey('cancel-confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel booking')),
        ],
      ),
    );
    if (ok == true) {
      final r = store.cancel(pnr);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Booking cancelled. Refund: ${Fmt.inr(r)} (demo).')));
      }
    }
  }
}

class _CancelledNote extends StatelessWidget {
  const _CancelledNote();

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Padding(
          padding: EdgeInsets.all(AppSpace.l),
          child: Text('This booking has been cancelled.', key: ValueKey('cancelled-note')),
        ),
      );
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({required this.index, required this.segment, required this.passengers, required this.total});

  final int index, total;
  final BookedSegment segment;
  final List<Passenger> passengers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = segment.flight;
    return SectionCard(
      title: '${f.from} → ${f.to}${total > 1 ? '  (flight ${index + 1})' : ''}',
      subtitle: '${Fmt.date(f.departure)} · ${f.flightNos}',
      icon: Icons.flight_takeoff,
      trailing: Chip(
        label: Text(segment.family.label),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: AppColors.fare(segment.family)),
        backgroundColor: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Fmt.time(f.departure)} → ${Fmt.time(f.arrival)} · ${Fmt.duration(f.totalDuration)} · '
            '${f.stops == 0 ? 'Non-stop' : '${f.stops} stop${f.stops > 1 ? 's' : ''} via ${f.viaAirports.join(', ')}'}',
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: AppSpace.xl),
          for (final p in passengers)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Text(
                '${p.fullName}: seat ${segment.seats[p.id] ?? 'auto-assigned at check-in'}'
                ' · meal ${SampleData.mealsById[segment.meals[p.id]]?.name ?? 'none'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  const _FareCard({required this.fare, required this.passengers, required this.segments});

  final FareBreakdown fare;
  final int passengers, segments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget line(String key, String label, int amount, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Row(
            children: [
              Expanded(child: Text(label, style: strong ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)),
              Text(Fmt.inr(amount),
                  key: ValueKey('fare-$key'), style: strong ? theme.textTheme.titleLarge : theme.textTheme.bodyMedium),
            ],
          ),
        );
    return SectionCard(
      title: 'Fare breakdown',
      subtitle: '$passengers passenger${passengers == 1 ? '' : 's'} · $segments flight${segments == 1 ? '' : 's'}',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          line('base', 'Base fare', fare.baseFare),
          line('family', 'Fare family charges', fare.familyCharges),
          line('seats', 'Seat fees', fare.seatFees),
          line('meals', 'Meals', fare.mealCharges),
          line('addons', 'Add-ons', fare.addOnCharges),
          line('taxes', 'Taxes & fees', fare.taxesAndFees),
          const Divider(),
          line('total', 'Total (demo)', fare.total, strong: true),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.segments, required this.subject, required this.now, required this.real});

  final List<BookedSegment> segments;
  final Booking subject;
  final DateTime now;
  final bool real;

  String _example() {
    final fare = subject.fare;
    final refund = PricingEngine.cancellationRefund(subject, now);
    final allFlex = segments.every((s) => s.family == FareFamily.flex);
    final when = real ? 'if you cancel now' : 'if you cancelled right after booking';
    if (allFlex) {
      final cutoff = Fmt.time(subject.departure.subtract(const Duration(hours: 2)));
      return 'Flex: full refund of ${Fmt.inr(fare.total)} when cancelled up to 2 h before departure '
          '(${Fmt.date(subject.departure)}, before $cutoff). After that the refund is ₹0. '
          'Worked example $when: refund ${Fmt.inr(refund)}.';
    }
    final fees = [
      for (final s in segments) s.family.info.cancellationFee,
    ];
    final feeTotal = fees.fold<int>(0, (a, b) => a + b);
    return 'Refund = total − cancellation fee per flight − add-ons. '
        'Worked example $when: ${Fmt.inr(fare.total)} − ${Fmt.inr(feeTotal)} '
        '(${segments.map((s) => '${s.family.label} ${Fmt.inr(s.family.info.cancellationFee)}').join(' + ')}) '
        '− ${Fmt.inr(fare.addOnCharges)} add-ons = ${Fmt.inr(refund)} (never below ₹0). '
        'After departure the refund is ₹0.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final families = {for (final s in segments) s.family}.toList()..sort((a, b) => a.index.compareTo(b.index));
    return SectionCard(
      title: 'Cancellation & change policy',
      icon: Icons.policy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in families) ...[
            Text('${f.label} fare', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.fare(f))),
            Text('Change: ${f.info.changeText}', style: theme.textTheme.bodySmall),
            Text('Cancellation: ${f.info.cancellationText}', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpace.s),
          ],
          Container(
            key: const ValueKey('refund-example'),
            padding: const EdgeInsets.all(AppSpace.m),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radius / 2),
            ),
            child: Text(_example(), style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
