import 'package:flutter/material.dart';

import '../logic/formatters.dart';
import '../logic/pricing.dart';
import '../models/fare_family.dart';
import '../models/passenger.dart';
import '../models/seat.dart';
import '../theme.dart';

/// Interactive A320neo cabin: 30 rows, A B C | aisle | D E F.
///
/// - [seats]: the 180 seats (e.g. `BookingStore.cabinFor(flight)`).
/// - [selected]: seat id of the active passenger (drawn solid).
/// - [onTap]: called for any non-occupied seat and for seats in
///   [passengerSeats]; occupied seats are disabled.
/// - [passengerSeats]: seatId → short marker label (e.g. initials) for seats
///   already held by this party; build it with [CabinMap.markersFrom].
/// - [family]: when given, prices in semantics labels follow the Flex rule.
///
/// Not vertically scrollable: put it inside a scroll view. It scrolls
/// horizontally when narrower than ~310 px. Each seat has key `seat-<id>`.
class CabinMap extends StatelessWidget {
  const CabinMap({
    super.key,
    required this.seats,
    this.selected,
    required this.onTap,
    this.passengerSeats = const {},
    this.family,
    this.seatSize = 36,
  });

  final List<Seat> seats;
  final String? selected;
  final ValueChanged<Seat>? onTap;
  final Map<String, String> passengerSeats;
  final FareFamily? family;
  final double seatSize;

  /// passengerId → seatId (the draft/booking shape) into seatId → initials.
  static Map<String, String> markersFrom(Map<String, String> seatByPassenger, List<Passenger> passengers) => {
        for (final e in seatByPassenger.entries)
          e.value: passengers.where((p) => p.id == e.key).map((p) => p.initials).firstOrNull ?? '•',
      };

  /// The tier legend (see [CabinLegend]).
  static Widget legend({FareFamily? family}) => CabinLegend(family: family);

  @override
  Widget build(BuildContext context) {
    final byId = {for (final s in seats) s.id: s};
    final theme = Theme.of(context);
    final gap = seatSize * 0.12;
    final cell = seatSize + gap * 2;
    final aisle = seatSize * 0.9;
    const border = 2.0;
    final width = cell * 6 + aisle + AppSpace.l * 2 + border * 2;

    Widget header() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in CabinLayout.leftBlock) _label(context, l, cell),
            SizedBox(width: aisle),
            for (final l in CabinLayout.rightBlock) _label(context, l, cell),
          ],
        );

    final rows = <Widget>[];
    for (var r = 1; r <= CabinLayout.rows; r++) {
      if (r == CabinLayout.exitRows.first) rows.add(_exitMarker(context, cell * 6 + aisle));
      rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final l in CabinLayout.leftBlock) _seat(context, byId['$r$l'] ?? Seat.at(r, l), cell),
          SizedBox(
            width: aisle,
            child: Text('$r', textAlign: TextAlign.center, style: theme.textTheme.labelSmall),
          ),
          for (final l in CabinLayout.rightBlock) _seat(context, byId['$r$l'] ?? Seat.at(r, l), cell),
        ],
      ));
      if (r == CabinLayout.exitRows.last) rows.add(_exitMarker(context, cell * 6 + aisle));
    }

    final fuselage = Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.xl, AppSpace.l, AppSpace.l),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant, width: border),
        borderRadius: BorderRadius.vertical(top: Radius.circular(width / 2), bottom: const Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: width * 0.18),
          Text('FRONT', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2)),
          const SizedBox(height: AppSpace.s),
          header(),
          ...rows,
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: c.maxWidth.isFinite ? c.maxWidth : width),
          child: Center(child: fuselage),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String l, double cell) => SizedBox(
        width: cell,
        child: Text(l, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
      );

  Widget _exitMarker(BuildContext context, double w) {
    final t = Theme.of(context);
    return SizedBox(
      width: w,
      child: Row(
        children: [
          Text('◀ EXIT', style: t.textTheme.labelSmall?.copyWith(color: AppColors.danger)),
          const Expanded(child: Divider(indent: 6, endIndent: 6)),
          Text('EXIT ▶', style: t.textTheme.labelSmall?.copyWith(color: AppColors.danger)),
        ],
      ),
    );
  }

  Widget _seat(BuildContext context, Seat seat, double cell) {
    final theme = Theme.of(context);
    final marker = passengerSeats[seat.id];
    final isSelected = seat.id == selected;
    final ours = marker != null;
    final disabled = seat.occupied && !ours && !isSelected;
    final tierColor = AppColors.tier(seat.tier);
    final price = family == null ? seat.price : PricingEngine.seatFee(seat, family!);

    final Color fill;
    final Color border;
    final Color fg;
    if (disabled) {
      fill = AppColors.seatOccupied.withValues(alpha: 0.5);
      border = AppColors.seatOccupied;
      fg = theme.colorScheme.outline;
    } else if (isSelected) {
      fill = theme.colorScheme.primary;
      border = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimary;
    } else if (ours) {
      fill = theme.colorScheme.primaryContainer;
      border = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimaryContainer;
    } else {
      fill = tierColor.withValues(alpha: 0.16);
      border = tierColor;
      fg = tierColor;
    }

    final state = disabled ? 'occupied' : (isSelected ? 'selected' : (ours ? 'held by $marker' : 'available'));
    return SizedBox(
      width: cell,
      height: cell,
      child: Center(
        child: Semantics(
          button: true,
          enabled: !disabled,
          selected: isSelected,
          label: 'Seat ${seat.id}, ${seat.position}, ${seat.tier.label}, '
              '${price == 0 ? 'free' : Fmt.inr(price)}, $state',
          child: ExcludeSemantics(
            child: Material(
              key: ValueKey('seat-${seat.id}'),
              color: fill,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(4)),
                side: BorderSide(color: border, width: isSelected ? 2 : 1.2),
              ),
              child: InkWell(
                onTap: disabled || onTap == null ? null : () => onTap!(seat),
                child: SizedBox(
                  width: seatSize,
                  height: seatSize,
                  child: Center(
                    child: disabled
                        ? Icon(Icons.close, size: seatSize * 0.4, color: fg)
                        : Text(
                            marker ?? seat.letter,
                            style: theme.textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Legend: each tier with price and pitch, plus occupied / selected swatches.
/// With [family] = Flex, standard tiers read "Free with Flex".
class CabinLegend extends StatelessWidget {
  const CabinLegend({super.key, this.family});

  final FareFamily? family;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(Color fill, Color border, String title, String sub) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(color: border, width: 1.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppSpace.s),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: theme.textTheme.labelLarge),
                  Text(sub, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        );

    const sample = {SeatTier.xl: '1A', SeatTier.front: '2A', SeatTier.standard: '20A', SeatTier.standardMiddle: '20B'};
    String priceOf(SeatTier t) {
      final p = family == null ? t.price : PricingEngine.seatFee(Seat.tryParse(sample[t]!)!, family!);
      return p == 0 ? 'Free with Flex' : Fmt.inr(p);
    }

    return Wrap(
      spacing: AppSpace.l,
      runSpacing: AppSpace.m,
      children: [
        for (final t in SeatTier.values)
          item(AppColors.tier(t).withValues(alpha: 0.16), AppColors.tier(t), '${t.label} · ${priceOf(t)}', t.legroom),
        item(AppColors.seatOccupied.withValues(alpha: 0.5), AppColors.seatOccupied, 'Occupied', 'Not available'),
        item(theme.colorScheme.primary, theme.colorScheme.primary, 'Selected', 'Current passenger'),
        item(theme.colorScheme.primaryContainer, theme.colorScheme.primary, 'Your party', 'Initials shown'),
      ],
    );
  }
}
