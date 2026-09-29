import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../logic/formatters.dart';
import '../models/models.dart';
import '../state/booking_store.dart';
import '../theme.dart';
import '../widgets/journey_progress.dart';
import '../widgets/notification_bell.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';
import 'fare_calendar_screen.dart';
import 'flight_results_screen.dart';

enum _TripType { oneWay, roundTrip, multiCity }

class _Row {
  _Row(this.from, this.to, this.date);
  String from;
  String to;
  DateTime date;
}

/// F1: flight search (one-way / round trip / multi-city) with a fare calendar.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _maxSegments = 4;

  _TripType _type = _TripType.oneWay;
  late final List<_Row> _rows;
  late DateTime _returnDate;
  int _pax = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = _today();
    final first = today.add(const Duration(days: 7));
    _rows = [_Row('DEL', 'BOM', first)];
    _returnDate = first.add(const Duration(days: 3));
  }

  DateTime _today() {
    final n = context.read<BookingStore>().clock();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _clampDate(DateTime d) {
    final today = _today();
    final last = today.add(const Duration(days: 59));
    if (d.isBefore(today)) return today;
    if (d.isAfter(last)) return last;
    return d;
  }

  Future<void> _pickAirport(int index, {required bool isFrom}) async {
    final row = _rows[index];
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AirportPicker(selected: isFrom ? row.from : row.to, disabled: isFrom ? row.to : row.from),
    );
    if (code == null) return;
    setState(() {
      if (isFrom) {
        row.from = code;
      } else {
        row.to = code;
      }
      _error = null;
    });
  }

  Future<void> _pickDate(int index, {bool returnLeg = false}) async {
    final row = _rows[index];
    final from = returnLeg ? row.to : row.from;
    final to = returnLeg ? row.from : row.to;
    if (from == to) {
      setState(() => _error = 'Choose two different airports first.');
      return;
    }
    final picked = await Navigator.of(context).push<DateTime>(MaterialPageRoute(
      builder: (_) => FareCalendarScreen(
        from: from,
        to: to,
        initialDate: returnLeg ? _returnDate : row.date,
      ),
    ));
    if (picked == null || !mounted) return;
    setState(() {
      _error = null;
      if (returnLeg) {
        _returnDate = picked;
      } else {
        row.date = picked;
        if (_type == _TripType.roundTrip && _returnDate.isBefore(picked)) _returnDate = picked;
        if (_type == _TripType.multiCity) {
          for (var i = index + 1; i < _rows.length; i++) {
            if (_rows[i].date.isBefore(picked)) _rows[i].date = picked;
          }
        }
      }
    });
  }

  void _swap(_Row row) => setState(() {
        final t = row.from;
        row.from = row.to;
        row.to = t;
      });

  void _setType(_TripType t) {
    setState(() {
      _type = t;
      _error = null;
      if (t == _TripType.multiCity) {
        if (_rows.length < 2) _addSegment();
      } else if (_rows.length > 1) {
        _rows.removeRange(1, _rows.length);
      }
    });
  }

  void _addSegment() {
    if (_rows.length >= _maxSegments) return;
    final prev = _rows.last;
    final dest = SampleData.airports.firstWhere((a) => a.code != prev.to && a.code != prev.from).code;
    _rows.add(_Row(prev.to, dest, _clampDate(prev.date.add(const Duration(days: 3)))));
  }

  void _search() {
    final today = _today();
    String? err;
    for (var i = 0; i < _rows.length && err == null; i++) {
      final r = _rows[i];
      if (r.from == r.to) err = 'Origin and destination must differ (segment ${i + 1}).';
      if (r.date.isBefore(today)) err = 'Segment ${i + 1} date is in the past.';
      if (err == null && i > 0 && r.date.isBefore(_rows[i - 1].date)) {
        err = 'Segment ${i + 1} cannot be before segment $i.';
      }
    }
    if (err == null && _type == _TripType.roundTrip && _returnDate.isBefore(_rows[0].date)) {
      err = 'Return date cannot be before departure.';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);
    final segments = [for (final r in _rows) Segment(from: r.from, to: r.to, date: r.date)];
    if (_type == _TripType.roundTrip) {
      segments.add(Segment(from: _rows[0].to, to: _rows[0].from, date: _returnDate));
    }
    context.read<BookingStore>().startDraft(segments, _pax);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FlightResultsScreen(segIndex: 0)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a flight'),
        actions: const [AppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
        children: [
          MaxWidthBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JourneyProgress(step: 1),
                const SizedBox(height: AppSpace.s),
                SegmentedButton<_TripType>(
                  key: const ValueKey('trip-type'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: _TripType.oneWay, label: Text('One-way'), icon: Icon(Icons.arrow_right_alt)),
                    ButtonSegment(value: _TripType.roundTrip, label: Text('Round trip'), icon: Icon(Icons.sync_alt)),
                    ButtonSegment(value: _TripType.multiCity, label: Text('Multi-city'), icon: Icon(Icons.alt_route)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => _setType(s.first),
                ),
                const SizedBox(height: AppSpace.l),
                for (var i = 0; i < _rows.length; i++) ...[
                  _segmentCard(context, i),
                  const SizedBox(height: AppSpace.m),
                ],
                if (_type == _TripType.multiCity && _rows.length < _maxSegments)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('add-segment'),
                      onPressed: () => setState(_addSegment),
                      icon: const Icon(Icons.add),
                      label: const Text('Add another flight'),
                    ),
                  ),
                if (_type == _TripType.roundTrip) ...[
                  SectionCard(
                    title: 'Return',
                    icon: Icons.flight_land,
                    child: _DateField(
                      key: const ValueKey('return-date'),
                      label: 'Return date',
                      date: _returnDate,
                      onTap: () => _pickDate(0, returnLeg: true),
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                ],
                SectionCard(
                  title: 'Passengers',
                  icon: Icons.people_outline,
                  child: Row(
                    children: [
                      Expanded(child: Text('$_pax ${_pax == 1 ? 'passenger' : 'passengers'} (max 6)')),
                      IconButton.outlined(
                        key: const ValueKey('pax-minus'),
                        tooltip: 'Fewer passengers',
                        onPressed: _pax > 1 ? () => setState(() => _pax--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text('$_pax',
                            key: const ValueKey('pax-count'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge),
                      ),
                      IconButton.outlined(
                        key: const ValueKey('pax-plus'),
                        tooltip: 'More passengers',
                        onPressed: _pax < 6 ? () => setState(() => _pax++) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpace.m),
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: AppSpace.s),
                      Expanded(
                        child: Text(_error!,
                            key: const ValueKey('search-error'),
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpace.l),
                FilledButton.icon(
                  key: const ValueKey('search-button'),
                  onPressed: _search,
                  icon: const Icon(Icons.search),
                  label: const Text('Search flights'),
                ),
                const SizedBox(height: AppSpace.m),
                Text(
                  'Tap a date to see the lowest fare for each day. Fares are demo data; no payment is taken.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentCard(BuildContext context, int i) {
    final row = _rows[i];
    final multi = _type == _TripType.multiCity;
    final from = _AirportField(
      key: ValueKey('from-$i'),
      label: 'From',
      code: row.from,
      onTap: () => _pickAirport(i, isFrom: true),
    );
    final to = _AirportField(
      key: ValueKey('to-$i'),
      label: 'To',
      code: row.to,
      onTap: () => _pickAirport(i, isFrom: false),
    );
    final swap = IconButton.filledTonal(
      key: ValueKey('swap-$i'),
      tooltip: 'Swap airports',
      onPressed: () => _swap(row),
      icon: const Icon(Icons.swap_horiz),
    );
    final date = _DateField(
      key: ValueKey('date-$i'),
      label: 'Departure date',
      date: row.date,
      onTap: () => _pickDate(i),
    );
    return SectionCard(
      title: multi ? 'Flight ${i + 1}' : 'Route',
      icon: Icons.flight_takeoff,
      trailing: multi && _rows.length > 2
          ? IconButton(
              key: ValueKey('remove-segment-$i'),
              tooltip: 'Remove flight ${i + 1}',
              onPressed: () => setState(() => _rows.removeAt(i)),
              icon: const Icon(Icons.close),
            )
          : null,
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= 640) {
          return Row(
            children: [
              Expanded(child: from),
              const SizedBox(width: AppSpace.s),
              swap,
              const SizedBox(width: AppSpace.s),
              Expanded(child: to),
              const SizedBox(width: AppSpace.m),
              Expanded(child: date),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: from),
                const SizedBox(width: AppSpace.s),
                swap,
                const SizedBox(width: AppSpace.s),
                Expanded(child: to),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            date,
          ],
        );
      }),
    );
  }
}

class _AirportField extends StatelessWidget {
  const _AirportField({super.key, required this.label, required this.code, required this.onTap});

  final String label;
  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '$label airport, ${SampleData.cityOf(code)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(code, style: theme.textTheme.titleLarge),
              Text(SampleData.cityOf(code), style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({super.key, required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '$label ${Fmt.date(date)}, opens fare calendar',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_month)),
          child: Text(Fmt.weekdayDayMonth(date), style: theme.textTheme.titleMedium),
        ),
      ),
    );
  }
}

class _AirportPicker extends StatefulWidget {
  const _AirportPicker({required this.selected, required this.disabled});

  final String selected;
  final String disabled;

  @override
  State<_AirportPicker> createState() => _AirportPickerState();
}

class _AirportPickerState extends State<_AirportPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = SampleData.airports
        .where((a) => q.isEmpty || a.code.toLowerCase().contains(q) || a.city.toLowerCase().contains(q) || a.name.toLowerCase().contains(q))
        .toList();
    final height = MediaQuery.sizeOf(context).height * 0.6;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, AppSpace.s),
              child: TextField(
                key: const ValueKey('airport-search'),
                autofocus: false,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search city or code'),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('No matching airport'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final a = list[i];
                        final off = a.code == widget.disabled;
                        return ListTile(
                          key: ValueKey('airport-${a.code}'),
                          leading: const Icon(Icons.local_airport_outlined),
                          title: Text(a.label),
                          subtitle: Text(a.name),
                          selected: a.code == widget.selected,
                          enabled: !off,
                          trailing: off ? const Text('Already chosen') : null,
                          onTap: off ? null : () => Navigator.of(context).pop(a.code),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
