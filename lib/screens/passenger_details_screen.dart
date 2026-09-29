import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/booking_store.dart';
import '../state/profile_store.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/journey_progress.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';
import 'seat_selection_screen.dart';

/// Step 3 of the journey: one form per passenger, with a chooser for saved
/// travellers. Validation blocks continuing until every form is valid.
class PassengerDetailsScreen extends StatefulWidget {
  const PassengerDetailsScreen({super.key});

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PaxControllers {
  _PaxControllers({
    String first = '',
    String last = '',
    String age = '',
    String ff = '',
  }) : first = TextEditingController(text: first),
       last = TextEditingController(text: last),
       age = TextEditingController(text: age),
       ff = TextEditingController(text: ff);

  final TextEditingController first, last, age, ff;

  void fill(Passenger p) {
    first.text = p.firstName;
    last.text = p.lastName;
    age.text = p.age.toString();
    ff.text = p.frequentFlyerNo ?? '';
  }

  void dispose() {
    first.dispose();
    last.dispose();
    age.dispose();
    ff.dispose();
  }
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  List<_PaxControllers> _forms = [];
  String? _lastError;

  @override
  void initState() {
    super.initState();
    final d = context.read<BookingStore>().draft;
    if (d != null) {
      _forms = List.generate(d.passengerCount, (i) {
        if (i < d.passengers.length) {
          final p = d.passengers[i];
          return _PaxControllers(
            first: p.firstName,
            last: p.lastName,
            age: p.age.toString(),
            ff: p.frequentFlyerNo ?? '',
          );
        }
        return _PaxControllers();
      });
    }
  }

  @override
  void dispose() {
    for (final f in _forms) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _pickSaved(int index) async {
    final travellers = context.read<ProfileStore>().allTravellers;
    final picked = await showModalBottomSheet<Passenger>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
              child: Text(
                'Saved travellers',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            if (travellers.isEmpty)
              const ListTile(
                title: Text('No saved travellers yet. Add some in Profile.'),
              ),
            for (final t in travellers)
              ListTile(
                key: ValueKey('saved-${t.id}'),
                leading: CircleAvatar(child: Text(t.initials)),
                title: Text(t.fullName),
                subtitle: Text(
                  'Age ${t.age}${t.frequentFlyerNo != null ? ' · FF ${t.frequentFlyerNo}' : ''}',
                ),
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _forms[index].fill(picked));
  }

  void _continue() {
    final store = context.read<BookingStore>();
    if (!_formKey.currentState!.validate()) {
      setState(
        () => _lastError = 'Please fix the highlighted fields to continue.',
      );
      return;
    }
    setState(() => _lastError = null);
    final existing = store.draft?.passengers ?? const <Passenger>[];
    final list = <Passenger>[
      for (var i = 0; i < _forms.length; i++)
        Passenger(
          id: i < existing.length ? existing[i].id : '',
          firstName: _forms[i].first.text.trim(),
          lastName: _forms[i].last.text.trim(),
          age: int.parse(_forms[i].age.text.trim()),
          frequentFlyerNo: _forms[i].ff.text.trim().isEmpty
              ? null
              : _forms[i].ff.text.trim(),
        ),
    ];
    store.setPassengers(list);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SeatSelectionScreen(segIndex: 0),
      ),
    );
  }

  String? _name(String? v, String what) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter $what';
    if (!RegExp(r"^[A-Za-z][A-Za-z .'-]*$").hasMatch(t)) {
      return 'Use letters only';
    }
    return null;
  }

  String? _age(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter age';
    if (n < 0 || n > 120) return 'Age must be 0-120';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<BookingStore>().draft;
    final theme = Theme.of(context);
    if (d == null || _forms.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Passenger details')),
        body: const EmptyState(
          icon: Icons.person_outline,
          title: 'No booking in progress',
          message: 'Start from the Book tab.',
        ),
      );
    }
    final wide = Breakpoints.isWide(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Passenger details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpace.xl),
          children: [
            MaxWidthBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const JourneyProgress(step: 3),
                  Text(
                    'Who is travelling?',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'Enter names as on the ID used for travel. Demo only: nothing is sent anywhere.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpace.m),
                  for (var i = 0; i < _forms.length; i++) ...[
                    _paxCard(i, wide),
                    const SizedBox(height: AppSpace.m),
                  ],
                  if (_lastError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.s),
                      child: Text(
                        _lastError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      key: const ValueKey('passengers-continue'),
                      onPressed: _continue,
                      icon: const Icon(Icons.airline_seat_recline_normal),
                      label: const Text('Continue to seats'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paxCard(int i, bool wide) {
    final f = _forms[i];
    Widget field(
      TextEditingController c,
      String label, {
      String? Function(String?)? v,
      TextInputType? type,
      Key? key,
    }) => TextFormField(
      key: key,
      controller: c,
      keyboardType: type,
      textCapitalization: type == null
          ? TextCapitalization.words
          : TextCapitalization.none,
      decoration: InputDecoration(labelText: label),
      validator: v,
    );
    final first = field(
      f.first,
      'First name',
      v: (v) => _name(v, 'first name'),
      key: ValueKey('pax-$i-first'),
    );
    final last = field(
      f.last,
      'Last name',
      v: (v) => _name(v, 'last name'),
      key: ValueKey('pax-$i-last'),
    );
    final age = field(
      f.age,
      'Age',
      v: _age,
      type: TextInputType.number,
      key: ValueKey('pax-$i-age'),
    );
    final ff = field(
      f.ff,
      'Frequent Flyer no. (optional)',
      key: ValueKey('pax-$i-ff'),
    );
    const gap = SizedBox(width: AppSpace.m, height: AppSpace.m);
    return SectionCard(
      title: 'Passenger ${i + 1}',
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            key: ValueKey('pick-saved-$i'),
            onPressed: () => _pickSaved(i),
            icon: const Icon(Icons.bookmarks_outlined),
            label: const Text('Pick from saved travellers'),
          ),
          wide
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: first),
                        gap,
                        Expanded(child: last),
                      ],
                    ),
                    gap,
                    Row(
                      children: [
                        Expanded(child: age),
                        gap,
                        Expanded(flex: 2, child: ff),
                      ],
                    ),
                  ],
                )
              : Column(children: [first, gap, last, gap, age, gap, ff]),
        ],
      ),
    );
  }
}
