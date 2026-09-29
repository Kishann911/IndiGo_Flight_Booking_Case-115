import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/checkin_rules.dart';
import '../logic/formatters.dart';
import '../models/models.dart';
import '../state/booking_store.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/notification_bell.dart';
import '../widgets/responsive.dart';
import 'trip_summary_screen.dart';

/// Tab root: all bookings as Cards with status and the check-in window label.
class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookingStore>();
    final bookings = store.bookings;
    final now = store.clock();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: const [AppBarActions()],
      ),
      body: bookings.isEmpty
          ? const EmptyState(
              icon: Icons.luggage_outlined,
              title: 'No trips yet',
              message: 'Bookings you make in the Book tab appear here.')
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.m),
              itemBuilder: (_, i) => MaxWidthBox(child: _TripCard(booking: bookings[i], now: now)),
            ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.booking, required this.now});

  final Booking booking;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final b = booking;
    final cancelled = b.isCancelled;
    final open = !cancelled && CheckInRules.isOpen(b.departure, now);
    final window = cancelled ? 'Cancelled' : 'Web check-in: ${CheckInRules.windowLabel(b.departure, now)}';
    final statusColor = cancelled ? AppColors.danger : AppColors.success;
    return Card(
      key: ValueKey('trip-${b.pnr}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => TripSummaryScreen.forBooking(pnr: b.pnr))),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('PNR ${b.pnr}',
                        style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 1.5, color: scheme.primary)),
                  ),
                  Chip(
                    label: Text(cancelled ? 'Cancelled' : 'Confirmed'),
                    labelStyle: theme.textTheme.labelMedium?.copyWith(color: statusColor),
                    side: BorderSide(color: statusColor),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Text(b.routeLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpace.xs),
              Text(
                '${Fmt.date(b.departure)} · ${Fmt.time(b.departure)} · '
                '${b.passengers.length} passenger${b.passengers.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpace.s),
              Row(
                children: [
                  Icon(open ? Icons.check_circle_outline : Icons.schedule,
                      size: 18, color: open ? AppColors.success : scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpace.s),
                  Expanded(child: Text(window, style: theme.textTheme.bodyMedium)),
                  Text(Fmt.inr(b.fare.total), style: theme.textTheme.titleMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
