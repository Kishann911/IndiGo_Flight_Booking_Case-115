import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/profile_store.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/notification_bell.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';
import 'baggage_screen.dart';

/// F12: profile with frequent flyer number and saved travellers.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final me = store.me;
    final theme = Theme.of(context);
    final saved = store.savedTravellers;

    final profileCard = SectionCard(
      title: 'My profile',
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28, child: Text(me.initials, style: theme.textTheme.titleMedium)),
              const SizedBox(width: AppSpace.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me.fullName, key: const ValueKey('profile-name'), style: theme.textTheme.titleLarge),
                    Text('Age ${me.age}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.card_membership_outlined),
            title: const Text('Frequent Flyer number'),
            subtitle: Text(
              me.frequentFlyerNo ?? 'Not set',
              key: const ValueKey('ff-number'),
            ),
            trailing: IconButton(
              key: const ValueKey('edit-ff'),
              tooltip: 'Edit Frequent Flyer number',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editFrequentFlyer(context, store),
            ),
          ),
          ListTile(
            key: const ValueKey('open-baggage'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.luggage_outlined),
            title: const Text('Baggage tracker'),
            subtitle: const Text('RFID scans for your checked bags (simulated)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BaggageScreen())),
          ),
        ],
      ),
    );

    final travellersCard = SectionCard(
      title: 'Saved travellers',
      subtitle: 'Pick them quickly when booking',
      icon: Icons.group_outlined,
      trailing: FilledButton.tonalIcon(
        key: const ValueKey('add-traveller'),
        onPressed: () => _editTraveller(context, store),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add'),
      ),
      child: saved.isEmpty
          ? const EmptyState(icon: Icons.group_add_outlined, title: 'No saved travellers yet')
          : Column(
              children: [
                for (final t in saved)
                  ListTile(
                    key: ValueKey('traveller-${t.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(t.initials)),
                    title: Text(t.fullName),
                    subtitle: Text(
                        'Age ${t.age}${t.frequentFlyerNo == null ? '' : ' · FF ${t.frequentFlyerNo}'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: ValueKey('edit-${t.id}'),
                          tooltip: 'Edit ${t.fullName}',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editTraveller(context, store, existing: t),
                        ),
                        IconButton(
                          key: ValueKey('delete-${t.id}'),
                          tooltip: 'Delete ${t.fullName}',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, store, t),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );

    final aboutCard = SectionCard(
      title: 'About',
      icon: Icons.info_outline,
      child: Text(
        'Case 115 — Flight Booking & Check-in. Real-time status, push notifications and RFID '
        'baggage tracking are simulated locally; no payment is taken and there is no backend.\n\n'
        'Case-study prototype for coursework — not affiliated with InterGlobe Aviation / IndiGo.',
        key: const ValueKey('about-disclaimer'),
        style: theme.textTheme.bodyMedium,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [AppBarActions()],
      ),
      body: MaxWidthBox(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.m),
          children: [
            if (Breakpoints.isWide(context))
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: profileCard),
                  const SizedBox(width: AppSpace.l),
                  Expanded(child: travellersCard),
                ],
              )
            else ...[
              profileCard,
              const SizedBox(height: AppSpace.m),
              travellersCard,
            ],
            const SizedBox(height: AppSpace.m),
            aboutCard,
          ],
        ),
      ),
    );
  }

  Future<void> _editFrequentFlyer(BuildContext context, ProfileStore store) async {
    final ctrl = TextEditingController(text: store.frequentFlyerNo ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Frequent Flyer number'),
        content: TextField(
          key: const ValueKey('ff-field'),
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Number', helperText: 'Leave blank to remove'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            key: const ValueKey('ff-save'),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) store.setFrequentFlyerNo(result);
  }

  Future<void> _editTraveller(BuildContext context, ProfileStore store, {Passenger? existing}) async {
    final result = await showDialog<Passenger>(
      context: context,
      builder: (ctx) => _TravellerDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      store.addTraveller(result);
    } else {
      store.updateTraveller(result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, ProfileStore store, Passenger t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${t.fullName}?'),
        content: const Text('This removes the saved traveller from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            key: const ValueKey('confirm-delete'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) store.removeTraveller(t.id);
  }
}

class _TravellerDialog extends StatefulWidget {
  const _TravellerDialog({this.existing});

  final Passenger? existing;

  @override
  State<_TravellerDialog> createState() => _TravellerDialogState();
}

class _TravellerDialogState extends State<_TravellerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.existing?.firstName ?? '');
  late final _last = TextEditingController(text: widget.existing?.lastName ?? '');
  late final _age = TextEditingController(text: widget.existing?.age.toString() ?? '');
  late final _ff = TextEditingController(text: widget.existing?.frequentFlyerNo ?? '');

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _age.dispose();
    _ff.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final ff = _ff.text.trim();
    final e = widget.existing;
    Navigator.pop(
      context,
      Passenger(
        id: e?.id ?? '',
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        age: int.parse(_age.text.trim()),
        frequentFlyerNo: ff.isEmpty ? null : ff,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add traveller' : 'Edit traveller'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('traveller-first'),
                controller: _first,
                decoration: const InputDecoration(labelText: 'First name'),
                textCapitalization: TextCapitalization.words,
                validator: _required,
              ),
              TextFormField(
                key: const ValueKey('traveller-last'),
                controller: _last,
                decoration: const InputDecoration(labelText: 'Last name'),
                textCapitalization: TextCapitalization.words,
                validator: _required,
              ),
              TextFormField(
                key: const ValueKey('traveller-age'),
                controller: _age,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return (n == null || n < 0 || n > 120) ? 'Enter an age 0–120' : null;
                },
              ),
              TextFormField(
                key: const ValueKey('traveller-ff'),
                controller: _ff,
                decoration: const InputDecoration(labelText: 'Frequent Flyer no. (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(key: const ValueKey('traveller-save'), onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
