import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/formatters.dart';
import '../models/models.dart';
import '../state/baggage_service.dart';
import '../state/booking_store.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';
import '../widgets/simulated_tag.dart';

/// F8: baggage tracker with (simulated) RFID scans.
class BaggageScreen extends StatefulWidget {
  const BaggageScreen({super.key});

  @override
  State<BaggageScreen> createState() => _BaggageScreenState();
}

class _BaggageScreenState extends State<BaggageScreen> {
  BaggageService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service ??= context.read<BaggageService>();
  }

  @override
  void dispose() {
    // Do not leave the demo timer running after leaving the screen.
    final service = _service;
    if (service != null && service.isAutoScanning) {
      WidgetsBinding.instance.addPostFrameCallback((_) => service.stopAutoScan());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BaggageService>();
    final bookings = context.watch<BookingStore>();
    for (final b in bookings.bookings) {
      service.ensureBagsForBooking(b);
    }
    final active = {for (final b in bookings.bookings.where((b) => !b.isCancelled)) b.pnr: b};
    final bags = service.bags.where((b) => active.containsKey(b.pnr)).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Baggage tracker')),
      body: bags.isEmpty
          ? const EmptyState(
              icon: Icons.luggage_outlined,
              title: 'No checked bags',
              message: 'Bags appear for Classic and Flex bookings, or when extra baggage is added.',
            )
          : MaxWidthBox(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.m),
                children: [
                  Wrap(
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('RFID baggage tracking', style: theme.textTheme.titleLarge),
                      const SimulatedTag(label: 'simulated'),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s),
                  Card(
                    child: SwitchListTile(
                      key: const ValueKey('auto-scan'),
                      secondary: const Icon(Icons.sensors),
                      title: const Text('Auto-scan (demo)'),
                      subtitle: const Text('Advances the first uncollected bag every few seconds (simulated).'),
                      value: service.isAutoScanning,
                      onChanged: (on) => on ? service.startAutoScan() : service.stopAutoScan(),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s),
                  for (final bag in bags) ...[
                    _BagCard(bag: bag, booking: active[bag.pnr]!, service: service),
                    const SizedBox(height: AppSpace.s),
                  ],
                ],
              ),
            ),
    );
  }
}

class _BagCard extends StatelessWidget {
  const _BagCard({required this.bag, required this.booking, required this.service});

  final Bag bag;
  final Booking booking;
  final BaggageService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pax = booking.passengerById(bag.passengerId);
    final next = bag.nextStage;
    return SectionCard(
      title: bag.rfidTag,
      subtitle: '${pax?.fullName ?? 'Passenger'} · PNR ${bag.pnr} · ${bag.from} → ${bag.to}',
      icon: Icons.luggage,
      trailing: Chip(
        label: Text(bag.stage?.label ?? 'Not scanned yet'),
        visualDensity: VisualDensity.compact,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final stage in BagScanStage.values) _stageRow(context, stage),
          const SizedBox(height: AppSpace.s),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: ValueKey('scan-${bag.rfidTag}'),
              onPressed: next == null ? null : () => service.scanNext(bag.rfidTag),
              icon: const Icon(Icons.sensors),
              label: Text(next == null ? 'Bag collected' : 'Simulate RFID scan'),
            ),
          ),
          if (next != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Text('Next scan point: ${next.label} (simulated)',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }

  Widget _stageRow(BuildContext context, BagScanStage stage) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scan = bag.scans.where((s) => s.stage == stage).firstOrNull;
    final done = scan != null;
    final isLast = stage == BagScanStage.values.last;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20, color: done ? AppColors.success : scheme.outline),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: done ? AppColors.success : scheme.outlineVariant)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.label,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: done ? FontWeight.w600 : null, color: done ? null : scheme.outline)),
                  if (scan != null)
                    Text('${scan.location} · ${Fmt.time(scan.at)}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
