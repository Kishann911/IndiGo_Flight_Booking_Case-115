import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/formatters.dart';
import '../models/models.dart';
import '../state/booking_store.dart';
import '../state/shell_controller.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';

/// Shown after "Confirm booking". Demo only: no payment is taken.
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.pnr});

  final String pnr;

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BookingStore>().byPnr(pnr);
    final theme = Theme.of(context);
    if (b == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking confirmed')),
        body: const EmptyState(icon: Icons.search_off, title: 'Booking not found'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Booking confirmed'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
        children: [
          MaxWidthBox(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.check_circle, size: 64, color: AppColors.success),
                const SizedBox(height: AppSpace.m),
                Text('You are all set!', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: AppSpace.l),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.l),
                    child: Column(
                      children: [
                        Text('Your PNR', style: theme.textTheme.labelMedium),
                        SelectableText(
                          b.pnr,
                          key: const ValueKey('confirmed-pnr'),
                          style: theme.textTheme.displaySmall
                              ?.copyWith(letterSpacing: 4, color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s),
                Text('Demo booking — no payment is taken.',
                    style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: AppSpace.l),
                SectionCard(
                  title: b.routeLabel,
                  icon: Icons.flight_takeoff,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final s in b.segments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.xs),
                          child: Text(
                            '${s.flight.flightNos} · ${s.flight.from} → ${s.flight.to} · '
                            '${Fmt.weekdayDayMonth(s.flight.departure)}, ${Fmt.time(s.flight.departure)} · ${s.family.label}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      const SizedBox(height: AppSpace.xs),
                      Text('Passengers: ${b.passengers.map((p) => p.fullName).join(', ')}',
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: AppSpace.xs),
                      Text('Total (demo): ${Fmt.inr(b.fare.total)}', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.l),
                Wrap(
                  spacing: AppSpace.m,
                  runSpacing: AppSpace.m,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('go-my-trips'),
                      onPressed: () => ShellController.goTo(context, ShellTab.trips),
                      icon: const Icon(Icons.luggage_outlined),
                      label: const Text('Go to My Trips'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('go-web-checkin'),
                      onPressed: () => ShellController.goTo(context, ShellTab.checkIn,
                          checkInPnr: b.pnr, checkInLastName: b.passengers.first.lastName),
                      icon: const Icon(Icons.how_to_reg_outlined),
                      label: const Text('Web check-in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
