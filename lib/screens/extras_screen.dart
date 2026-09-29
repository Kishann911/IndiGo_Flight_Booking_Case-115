import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../logic/formatters.dart';
import '../models/models.dart';
import '../state/booking_store.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/journey_progress.dart';
import '../widgets/responsive.dart';
import '../widgets/section_card.dart';
import 'trip_summary_screen.dart';

/// Step 5: add-ons (F10) and meal pre-order (F9).
class ExtrasScreen extends StatefulWidget {
  const ExtrasScreen({super.key});

  @override
  State<ExtrasScreen> createState() => _ExtrasScreenState();
}

class _ExtrasScreenState extends State<ExtrasScreen> {
  String? _cuisine;
  final Set<String> _diet = {};

  List<Meal> get _meals => [
        for (final m in SampleData.meals)
          if ((_cuisine == null || m.cuisine == _cuisine) && _diet.every(m.dietary.contains)) m,
      ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookingStore>();
    final d = store.draft;
    final theme = Theme.of(context);
    if (d == null || !d.passengersComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text('Extras & meals')),
        body: const EmptyState(icon: Icons.add_shopping_cart, title: 'No booking in progress'),
      );
    }
    final quote = store.draftQuote;
    final pax = d.passengerCount;
    final meals = _meals;

    final addOns = SectionCard(
      title: 'Add-ons',
      subtitle: 'Optional upgrades, applied to the whole booking',
      icon: Icons.add_circle_outline,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: Column(
        children: [
          for (final t in AddOnType.values)
            CheckboxListTile(
              key: ValueKey('addon-${t.name}'),
              value: d.hasAddOn(t),
              onChanged: (_) => store.toggleAddOn(t),
              title: Text(t.label),
              subtitle: Text(t.description),
              secondary: Text(
                t.perPassenger ? '${Fmt.inr(t.price)} × $pax = ${Fmt.inr(t.price * pax)}' : Fmt.inr(t.price),
                style: theme.textTheme.titleSmall,
              ),
            ),
        ],
      ),
    );

    final filters = SectionCard(
      title: 'Meal pre-order',
      subtitle: 'Filter by cuisine and dietary preference',
      icon: Icons.restaurant_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cuisine', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpace.xs),
          Wrap(spacing: AppSpace.s, runSpacing: AppSpace.xs, children: [
            ChoiceChip(
              key: const ValueKey('cuisine-all'),
              label: const Text('All'),
              selected: _cuisine == null,
              onSelected: (_) => setState(() => _cuisine = null),
            ),
            for (final c in Meal.cuisines)
              ChoiceChip(
                key: ValueKey('cuisine-$c'),
                label: Text(c),
                selected: _cuisine == c,
                onSelected: (_) => setState(() => _cuisine = _cuisine == c ? null : c),
              ),
          ]),
          const SizedBox(height: AppSpace.m),
          Text('Dietary preference', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpace.xs),
          Wrap(spacing: AppSpace.s, runSpacing: AppSpace.xs, children: [
            for (final t in Meal.dietaryTags)
              FilterChip(
                key: ValueKey('diet-$t'),
                label: Text(t),
                selected: _diet.contains(t),
                onSelected: (on) => setState(() => on ? _diet.add(t) : _diet.remove(t)),
              ),
          ]),
          const SizedBox(height: AppSpace.s),
          Text('${meals.length} meal${meals.length == 1 ? '' : 's'} match', key: const ValueKey('meal-count'), style: theme.textTheme.bodySmall),
        ],
      ),
    );

    final segments = [
      for (var i = 0; i < d.segmentCount; i++)
        if (d.flights[i] != null) _segmentMeals(context, store, i, meals),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Extras & meals')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpace.l),
              children: [
                MaxWidthBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const JourneyProgress(step: 5),
                      if (Breakpoints.isWide(context))
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: addOns),
                          const SizedBox(width: AppSpace.l),
                          Expanded(child: filters),
                        ])
                      else ...[addOns, const SizedBox(height: AppSpace.m), filters],
                      const SizedBox(height: AppSpace.m),
                      for (final w in segments) ...[w, const SizedBox(height: AppSpace.m)],
                    ],
                  ),
                ),
              ],
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
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text('Extras: ${Fmt.inr(quote.addOnCharges + quote.mealCharges)}',
                          key: const ValueKey('extras-total'), style: theme.textTheme.titleMedium),
                      Text('Trip total so far: ${Fmt.inr(quote.total)}', style: theme.textTheme.bodySmall),
                    ]),
                    FilledButton(
                      key: const ValueKey('extras-continue'),
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => const TripSummaryScreen())),
                      child: const Text('Continue to summary'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentMeals(BuildContext context, BookingStore store, int seg, List<Meal> meals) {
    final d = store.draft!;
    final flight = d.flights[seg]!;
    final family = d.families[seg]!;
    final theme = Theme.of(context);
    final info = family.info;
    final note = info.mealIncluded
        ? '${family.label} includes 1 complimentary meal per passenger. Your pre-ordered meal is free.'
        : 'Lite does not include a meal. Pre-ordered meals are paid, shown at the price below.';
    return SectionCard(
      title: 'Meals · ${flight.from} → ${flight.to}',
      subtitle: '${flight.flightNos} · ${Fmt.weekdayDayMonth(flight.departure)}',
      icon: Icons.ramen_dining_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(info.mealIncluded ? Icons.card_giftcard : Icons.info_outline, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpace.s),
            Expanded(child: Text(note, key: ValueKey('meal-note-$seg'), style: theme.textTheme.bodySmall)),
          ]),
          const SizedBox(height: AppSpace.m),
          for (final p in d.passengers) ...[
            _mealPicker(store, seg, p, family, meals),
            const SizedBox(height: AppSpace.m),
          ],
        ],
      ),
    );
  }

  Widget _mealPicker(BookingStore store, int seg, Passenger p, FareFamily family, List<Meal> filtered) {
    final currentId = store.draft!.mealFor(seg, p.id);
    final current = currentId == null ? null : SampleData.mealsById[currentId];
    // Keep the chosen meal selectable even if a filter hides it.
    final options = [...filtered];
    if (current != null && !options.any((m) => m.id == current.id)) options.insert(0, current);
    String priceOf(Meal m) => family.info.mealIncluded ? 'complimentary' : Fmt.inr(m.price);
    return DropdownButtonFormField<String?>(
      key: ValueKey('meal-$seg-${p.id}'),
      isExpanded: true,
      initialValue: currentId,
      decoration: InputDecoration(labelText: '${p.fullName} (meal)'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('No meal')),
        for (final m in options)
          DropdownMenuItem<String?>(
            value: m.id,
            child: Text('${m.name} · ${m.dietary.join('/')} · ${priceOf(m)}', overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => store.setMeal(seg, p.id, v),
    );
  }
}
