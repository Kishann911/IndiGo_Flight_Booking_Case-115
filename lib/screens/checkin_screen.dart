import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../logic/checkin_rules.dart';
import '../logic/formatters.dart';
import '../models/models.dart';
import '../state/booking_store.dart';
import '../state/shell_controller.dart';
import '../theme.dart';
import '../widgets/cabin_map.dart';
import '../widgets/notification_bell.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';
import 'boarding_pass_screen.dart';

/// F5: web check-in (PNR + last name, seat confirm or change, boarding pass).
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _pnr = TextEditingController();
  final _last = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _foundPnr;
  String? _error;
  int _seg = 0;
  String? _activePax;
  bool _showMap = false;

  /// passengerId → seat id chosen for the selected segment.
  Map<String, String> _chosen = {};

  @override
  void dispose() {
    _pnr.dispose();
    _last.dispose();
    super.dispose();
  }

  void _lookup(BookingStore store) {
    if (!_formKey.currentState!.validate()) return;
    final b = store.findByPnr(_pnr.text, _last.text);
    setState(() {
      if (b == null || b.isCancelled) {
        _foundPnr = null;
        _error = b != null && b.isCancelled
            ? 'This booking has been cancelled.'
            : 'No booking found for that PNR and last name. Check both and try again.';
      } else {
        _error = null;
        _foundPnr = b.pnr;
        _selectSegment(b, 0);
      }
    });
  }

  void _selectSegment(Booking b, int i) {
    _seg = i;
    _chosen = Map.of(b.segments[i].seats);
    _activePax = b.passengers.first.id;
    _showMap = false;
  }

  void _checkIn(BookingStore store, Booking b) {
    final failed = <String>[];
    String? firstDone;
    for (final p in b.passengers) {
      if (b.isCheckedIn(_seg, p.id)) {
        firstDone ??= p.id;
        continue;
      }
      if (store.checkIn(b.pnr, _seg, p.id, _chosen[p.id])) {
        firstDone ??= p.id;
      } else {
        failed.add(p.fullName);
      }
    }
    if (failed.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not check in ${failed.join(', ')}. The window may be closed or the seat is taken.'),
      ));
      return;
    }
    if (firstDone == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BoardingPassScreen(pnr: b.pnr, segIndex: _seg, passengerId: firstDone!),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookingStore>();
    final shell = context.watch<ShellController>();
    if (shell.pendingCheckInPnr != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final p = context.read<ShellController>().takeCheckInPnr();
        if (p != null) setState(() => _pnr.text = p);
      });
    }
    final booking = _foundPnr == null ? null : store.byPnr(_foundPnr!);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Web check-in'),
        actions: const [AppBarActions()],
      ),
      body: MaxWidthBox(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.m),
          children: [
            SectionCard(
              title: 'Find your booking',
              subtitle: 'Check-in opens 48 h and closes 60 min before departure',
              icon: Icons.how_to_reg_outlined,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(builder: (context, c) {
                      final pnrField = TextFormField(
                        key: const ValueKey('checkin-pnr'),
                        controller: _pnr,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'PNR', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().length != 6) ? 'PNR is 6 characters' : null,
                      );
                      final lastField = TextFormField(
                        key: const ValueKey('checkin-lastname'),
                        controller: _last,
                        decoration: const InputDecoration(labelText: 'Last name', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        onFieldSubmitted: (_) => _lookup(store),
                      );
                      if (c.maxWidth > 520) {
                        return Row(children: [
                          Expanded(child: pnrField),
                          const SizedBox(width: AppSpace.m),
                          Expanded(child: lastField),
                        ]);
                      }
                      return Column(children: [pnrField, const SizedBox(height: AppSpace.m), lastField]);
                    }),
                    const SizedBox(height: AppSpace.m),
                    FilledButton.icon(
                      key: const ValueKey('checkin-find'),
                      onPressed: () => _lookup(store),
                      icon: const Icon(Icons.search),
                      label: const Text('Find booking'),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.m),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                            const SizedBox(width: AppSpace.s),
                            Expanded(
                              child: Text(_error!,
                                  key: const ValueKey('checkin-error'),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.s),
                      child: Text('Demo: PNR ${SampleData.samplePnr}, last name Ojha.', style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ),
            if (booking != null) ...[
              const SizedBox(height: AppSpace.m),
              _bookingSection(context, store, booking),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bookingSection(BuildContext context, BookingStore store, Booking b) {
    final theme = Theme.of(context);
    final seg = b.segments[_seg];
    final now = store.clock();
    final dep = seg.flight.departure;
    final open = CheckInRules.isOpen(dep, now);
    final label = CheckInRules.windowLabel(dep, now);
    final allDone = b.passengers.every((p) => b.isCheckedIn(_seg, p.id));

    final segmentCard = SectionCard(
      title: 'PNR ${b.pnr} · ${b.routeLabel}',
      icon: Icons.confirmation_number_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (b.segments.length > 1) ...[
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.xs,
              children: [
                for (var i = 0; i < b.segments.length; i++)
                  ChoiceChip(
                    key: ValueKey('segment-$i'),
                    label: Text('${b.segments[i].flight.from} → ${b.segments[i].flight.to}'),
                    selected: i == _seg,
                    onSelected: (_) => setState(() => _selectSegment(b, i)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.m),
          ],
          Text('${seg.flight.flightNos} · ${Fmt.date(dep)} · departs ${Fmt.time(dep)}',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpace.s),
          Chip(
            key: const ValueKey('checkin-window'),
            avatar: Icon(open ? Icons.lock_open : Icons.lock_clock,
                size: 18, color: open ? AppColors.success : AppColors.warning),
            label: Text('Check-in window: $label'),
          ),
        ],
      ),
    );

    if (!open && !allDone) {
      return Column(children: [
        segmentCard,
        const SizedBox(height: AppSpace.m),
        SectionCard(
          child: Text(
            label == 'Closed'
                ? 'Web check-in has closed for this flight. Please see the airport counter.'
                : 'Web check-in is not open yet. Come back when the window opens.',
          ),
        ),
      ]);
    }

    final cabin = store.cabinFor(seg.flight, excludePnr: b.pnr);
    final markers = CabinMap.markersFrom(_chosen, b.passengers);

    final passengers = SectionCard(
      title: 'Passengers & seats',
      subtitle: allDone ? 'All checked in' : 'Confirm the seat or change it on the cabin map',
      icon: Icons.airline_seat_recline_normal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in b.passengers)
            Builder(builder: (context) {
              final done = b.isCheckedIn(_seg, p.id);
              final active = _showMap && _activePax == p.id && !done;
              return ListTile(
                key: ValueKey('checkin-pax-${p.id}'),
                contentPadding: EdgeInsets.zero,
                selected: active,
                leading: CircleAvatar(child: Text(p.initials)),
                title: Text(p.fullName),
                subtitle: Text(done
                    ? 'Checked in · seat ${seg.seats[p.id] ?? '—'}'
                    : 'Seat ${_chosen[p.id] ?? 'auto-assign'}'),
                trailing: done
                    ? TextButton(
                        key: ValueKey('view-pass-${p.id}'),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => BoardingPassScreen(pnr: b.pnr, segIndex: _seg, passengerId: p.id),
                        )),
                        child: const Text('Boarding pass'),
                      )
                    : OutlinedButton(
                        key: ValueKey('change-seat-${p.id}'),
                        onPressed: () => setState(() {
                          _activePax = p.id;
                          _showMap = true;
                        }),
                        child: const Text('Change seat'),
                      ),
              );
            }),
          if (!allDone) ...[
            const SizedBox(height: AppSpace.m),
            FilledButton.icon(
              key: const ValueKey('checkin-submit'),
              onPressed: open ? () => _checkIn(store, b) : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(b.passengers.length > 1 ? 'Check in all passengers' : 'Check in'),
            ),
          ],
        ],
      ),
    );

    final mapCard = SectionCard(
      title: 'Choose a seat',
      subtitle: 'Seat changes are free at check-in (demo)',
      icon: Icons.event_seat_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabinMap.legend(family: seg.family),
          const SizedBox(height: AppSpace.m),
          Center(
            child: CabinMap(
              seats: cabin,
              selected: _chosen[_activePax],
              passengerSeats: markers,
              family: seg.family,
              onTap: (s) {
                final pid = _activePax;
                if (pid == null) return;
                final heldByOther = _chosen.entries.any((e) => e.key != pid && e.value == s.id);
                if (heldByOther) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('That seat is held by another passenger.')));
                  return;
                }
                setState(() => _chosen = {..._chosen, pid: s.id});
              },
            ),
          ),
        ],
      ),
    );

    final wide = Breakpoints.isWide(context);
    if (wide && _showMap && !allDone) {
      return Column(children: [
        segmentCard,
        const SizedBox(height: AppSpace.m),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: passengers),
            const SizedBox(width: AppSpace.l),
            Expanded(child: mapCard),
          ],
        ),
      ]);
    }
    return Column(children: [
      segmentCard,
      const SizedBox(height: AppSpace.m),
      passengers,
      if (_showMap && !allDone) ...[const SizedBox(height: AppSpace.m), mapCard],
    ]);
  }
}
