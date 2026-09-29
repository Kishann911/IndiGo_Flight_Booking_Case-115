import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../logic/checkin_rules.dart';
import '../logic/formatters.dart';
import '../logic/pricing.dart';
import '../models/models.dart';
import 'booking_draft.dart';
import 'notification_store.dart';

export 'booking_draft.dart';

/// Owns confirmed bookings (persisted under [prefsKey]) and the in-progress
/// [draft]. Draft mutators throw [StateError] when there is no draft.
class BookingStore extends ChangeNotifier {
  static const prefsKey = 'indigo_bookings_v1';
  static const _pnrAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ23456789';

  BookingStore({this.notifications, DateTime Function()? clock, Random? random})
      : clock = clock ?? DateTime.now,
        _random = random ?? Random();

  final NotificationStore? notifications;

  /// Called with every newly confirmed booking (AppServices wires this to
  /// `FlightStatusService.trackBooking` so simulated pushes fire for it).
  void Function(Booking booking)? onBookingConfirmed;
  final DateTime Function() clock;
  final Random _random;
  final List<Booking> _bookings = [];
  BookingDraft? _draft;
  bool _loaded = false;
  Future<void> _saving = Future.value();

  /// Sorted by first departure (soonest first).
  List<Booking> get bookings => List.unmodifiable(_bookings);
  bool get loaded => _loaded;
  BookingDraft? get draft => _draft;

  // ---- Persistence ------------------------------------------------------

  /// Loads bookings; on first launch (key absent) seeds the sample booking.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    _bookings.clear();
    if (raw == null) {
      _bookings.add(SampleData.sampleBooking(clock()));
      _save();
    } else {
      try {
        _bookings.addAll((jsonDecode(raw) as List)
            .map((e) => Booking.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (e) {
        debugPrint('BookingStore: corrupt saved bookings, starting empty: $e');
      }
      _reseedSampleIfDeparted();
    }
    _sort();
    _loaded = true;
    notifyListeners();
  }

  /// The demo booking K7Q2ZP is seeded relative to the first launch. If it has
  /// since departed and was never touched (not cancelled, no check-in, same
  /// flight and seat), it is re-seeded relative to now so the demo check-in
  /// always works. A booking the user changed is left alone.
  void _reseedSampleIfDeparted() {
    final i = _bookings.indexWhere((b) => b.pnr == SampleData.samplePnr);
    if (i < 0) return;
    final b = _bookings[i];
    final fresh = SampleData.sampleBooking(clock());
    final unchanged = !b.isCancelled &&
        b.checkedIn.isEmpty &&
        b.segments.length == 1 &&
        b.segments.single.flight.id == fresh.segments.single.flight.id &&
        mapEquals(b.segments.single.seats, fresh.segments.single.seats);
    if (unchanged && !b.departure.isAfter(clock())) {
      _bookings[i] = fresh;
      _save();
    }
  }

  /// Completes when all pending writes are done.
  Future<void> flush() => _saving;

  void _save() {
    final data = jsonEncode(_bookings.map((b) => b.toJson()).toList());
    _saving = _saving.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(prefsKey, data);
      } catch (e) {
        debugPrint('BookingStore: saving bookings failed: $e');
      }
    });
  }

  void _sort() => _bookings.sort((a, b) => a.departure.compareTo(b.departure));

  // ---- Draft ------------------------------------------------------------

  BookingDraft _requireDraft() => _draft ?? (throw StateError('No booking draft in progress'));

  void startDraft(List<Segment> segments, int passengerCount) {
    if (segments.isEmpty) throw ArgumentError('At least one segment is required');
    _draft = BookingDraft.start(segments, passengerCount.clamp(1, 6));
    notifyListeners();
  }

  void clearDraft() {
    _draft = null;
    notifyListeners();
  }

  /// Picks [flight] + [family] for a segment. Changing the flight clears that
  /// segment's seats and meals.
  void chooseFlight(int segIndex, Flight flight, FareFamily family) {
    final d = _requireDraft();
    final flights = [...d.flights];
    final families = [...d.families];
    final seats = [...d.seats];
    final meals = [...d.meals];
    if (flights[segIndex]?.id != flight.id) {
      seats[segIndex] = const {};
      meals[segIndex] = const {};
    }
    flights[segIndex] = flight;
    families[segIndex] = family;
    _draft = d.copyWith(flights: flights, families: families, seats: seats, meals: meals);
    notifyListeners();
  }

  /// Replaces the passenger list. Passengers with an empty id get a unique
  /// id. Seats/meals of passengers no longer present are dropped.
  void setPassengers(List<Passenger> list) {
    final d = _requireDraft();
    final used = <String>{};
    final out = <Passenger>[];
    for (final p in list) {
      var id = p.id;
      if (id.isEmpty || used.contains(id)) {
        do {
          id = 'pax-${out.length + 1}-${_random.nextInt(1 << 20)}';
        } while (used.contains(id));
      }
      used.add(id);
      out.add(p.copyWith(id: id));
    }
    Map<String, String> keep(Map<String, String> m) =>
        {for (final e in m.entries) if (used.contains(e.key)) e.key: e.value};
    _draft = d.copyWith(
      passengers: List.unmodifiable(out),
      seats: d.seats.map(keep).toList(),
      meals: d.meals.map(keep).toList(),
    );
    notifyListeners();
  }

  /// Assigns [seatId] (null clears). A seat held by another passenger on the
  /// same segment moves to this passenger.
  void setSeat(int segIndex, String passengerId, String? seatId) {
    final d = _requireDraft();
    final m = Map<String, String>.from(d.seats[segIndex]);
    if (seatId == null) {
      m.remove(passengerId);
    } else {
      m.removeWhere((pid, s) => s == seatId && pid != passengerId);
      m[passengerId] = seatId;
    }
    final seats = [...d.seats]..[segIndex] = m;
    _draft = d.copyWith(seats: seats);
    notifyListeners();
  }

  /// Pre-orders [mealId] (null clears) for one passenger on one segment.
  void setMeal(int segIndex, String passengerId, String? mealId) {
    final d = _requireDraft();
    final m = Map<String, String>.from(d.meals[segIndex]);
    if (mealId == null) {
      m.remove(passengerId);
    } else {
      m[passengerId] = mealId;
    }
    final meals = [...d.meals]..[segIndex] = m;
    _draft = d.copyWith(meals: meals);
    notifyListeners();
  }

  /// Toggles an add-on. The two extra-baggage options are mutually exclusive.
  void toggleAddOn(AddOnType type) {
    final d = _requireDraft();
    final s = {...d.addOns};
    if (!s.remove(type)) {
      if (type.isBaggage) s.removeWhere((t) => t.isBaggage);
      s.add(type);
    }
    _draft = d.copyWith(addOns: s);
    notifyListeners();
  }

  /// Quote for the chosen segments so far (zero without a draft).
  FareBreakdown get draftQuote {
    final d = _draft;
    if (d == null) return FareBreakdown.zero;
    return PricingEngine.quote(
      segments: d.bookedSegments,
      passengers: d.passengerCount,
      addOns: d.addOns,
      today: clock(),
      mealsById: SampleData.mealsById,
      seatsById: CabinLayout.seatsById,
    );
  }

  /// Turns the complete draft into a confirmed booking (demo — no payment),
  /// persists it, adds a "booking" notification and clears the draft.
  Booking confirmDraft() {
    final d = _requireDraft();
    if (!d.isComplete) throw StateError('Draft is incomplete (flights or passengers missing)');
    final booking = Booking(
      pnr: _newPnr(),
      bookedAt: clock(),
      passengers: d.passengers,
      segments: d.bookedSegments,
      addOns: d.addOns,
      fare: draftQuote,
    );
    _bookings.add(booking);
    _sort();
    _draft = null;
    _save();
    onBookingConfirmed?.call(booking);
    notifyListeners();
    notifications?.push(
      title: 'Booking confirmed · ${booking.pnr}',
      body: 'PNR ${booking.pnr} · ${booking.routeLabel} · ${Fmt.weekdayDayMonth(booking.departure)}. '
          'Demo booking — no payment is taken.',
      kind: NotificationKind.booking,
    );
    return booking;
  }

  String _newPnr() {
    while (true) {
      final pnr = String.fromCharCodes(
          List.generate(6, (_) => _pnrAlphabet.codeUnitAt(_random.nextInt(_pnrAlphabet.length))));
      if (byPnr(pnr) == null) return pnr;
    }
  }

  // ---- Lookup -----------------------------------------------------------

  Booking? byPnr(String pnr) {
    final key = pnr.trim().toUpperCase();
    for (final b in _bookings) {
      if (b.pnr == key) return b;
    }
    return null;
  }

  /// PNR + any passenger's last name, both case-insensitive and trimmed.
  Booking? findByPnr(String pnr, String lastName) {
    final b = byPnr(pnr);
    if (b == null) return null;
    final ln = lastName.trim().toLowerCase();
    return b.passengers.any((p) => p.lastName.toLowerCase() == ln) ? b : null;
  }

  /// Cabin for [flight]: seeded occupancy plus seats held by other confirmed
  /// bookings on the same flight. Seats of [excludePnr] are shown free.
  List<Seat> cabinFor(Flight flight, {String? excludePnr}) {
    final held = <String>{};
    final own = <String>{};
    for (final b in _bookings) {
      if (b.isCancelled) continue;
      for (final s in b.segments) {
        if (s.flight.id != flight.id) continue;
        (b.pnr == excludePnr ? own : held).addAll(s.seats.values);
      }
    }
    final occupied = SampleData.occupiedSeats(flight.legs.first.flightNo, flight.departure)
        .union(held)
        .difference(own);
    return CabinLayout.build(occupied: occupied);
  }

  // ---- Check-in & cancel --------------------------------------------------

  /// Check-in seat rule: a change may not cost more than what was already
  /// paid. With a booked seat, [target]'s fee ([PricingEngine.seatFee] for
  /// [family]) must be at most the booked seat's fee. Without one, only
  /// standard / standard-middle seats are allowed (complimentary auto-assign
  /// alternatives, so nothing is charged).
  static bool seatChangeAllowed(Seat target, Seat? booked, FareFamily family) {
    if (booked == null) return target.tier.isStandard;
    return PricingEngine.seatFee(target, family) <= PricingEngine.seatFee(booked, family);
  }

  /// Web check-in for one passenger on one segment. [seatId] null keeps the
  /// booked seat or auto-assigns a free standard seat. Returns false when the
  /// booking/passenger is unknown, cancelled, the window is closed
  /// ([CheckInRules.isOpen]), the seat is taken, or the new seat would carry a
  /// higher fee than the booked one ([seatChangeAllowed]). Seat changes at
  /// check-in never change the fare.
  bool checkIn(String pnr, int segIndex, String passengerId, String? seatId) {
    final b = byPnr(pnr);
    if (b == null || b.isCancelled) return false;
    if (segIndex < 0 || segIndex >= b.segments.length) return false;
    if (b.passengerById(passengerId) == null) return false;
    final seg = b.segments[segIndex];
    if (!CheckInRules.isOpen(seg.flight.departure, clock())) return false;

    final current = seg.seats[passengerId];
    final cabin = {for (final s in cabinFor(seg.flight, excludePnr: b.pnr)) s.id: s};
    final heldByCompanions = {
      for (final e in seg.seats.entries)
        if (e.key != passengerId) e.value,
    };
    String? target = seatId ?? current;
    if (target == null) {
      for (final s in cabin.values.toList().reversed) {
        if (!s.occupied && s.tier.isStandard && !heldByCompanions.contains(s.id)) {
          target = s.id;
          break;
        }
      }
      if (target == null) return false;
    }
    final seat = cabin[target];
    if (seat == null) return false;
    if (heldByCompanions.contains(target)) return false;
    if (seat.occupied && target != current) return false;
    if (target != current && !seatChangeAllowed(seat, current == null ? null : cabin[current], seg.family)) {
      return false;
    }

    final segments = [...b.segments];
    segments[segIndex] = seg.copyWith(seats: {...seg.seats, passengerId: target});
    final updated = b.copyWith(
      segments: segments,
      checkedIn: {...b.checkedIn, Booking.checkInKey(segIndex, passengerId): true},
    );
    _replace(updated);
    final p = b.passengerById(passengerId)!;
    notifications?.push(
      title: 'Checked in · ${seg.flight.legs.first.flightNo}',
      body: '${p.fullName} is checked in on ${seg.flight.from} → ${seg.flight.to}, seat $target.',
      kind: NotificationKind.booking,
    );
    return true;
  }

  /// Refund the booking would get if cancelled now (0 if unknown).
  int refundQuote(String pnr) {
    final b = byPnr(pnr);
    return b == null ? 0 : PricingEngine.cancellationRefund(b, clock());
  }

  /// Why [pnr] cannot be cancelled, or null when it can. Once any passenger
  /// has checked in, the booking can no longer be cancelled.
  String? cancelBlockedReason(String pnr) {
    final b = byPnr(pnr);
    if (b != null && b.checkedIn.values.any((v) => v)) {
      return 'A passenger has already checked in, so this booking can no longer be cancelled.';
    }
    return null;
  }

  /// Cancels and returns the refund ([PricingEngine.cancellationRefund]);
  /// 0 for unknown, already-cancelled or blocked ([cancelBlockedReason]) bookings.
  int cancel(String pnr) {
    final b = byPnr(pnr);
    if (b == null || b.isCancelled || cancelBlockedReason(pnr) != null) return 0;
    final refund = PricingEngine.cancellationRefund(b, clock());
    _replace(b.copyWith(status: BookingStatus.cancelled));
    notifications?.push(
      title: 'Booking cancelled · ${b.pnr}',
      body: 'Refund of ${Fmt.inr(refund)} (demo — no money moves).',
      kind: NotificationKind.booking,
    );
    return refund;
  }

  void _replace(Booking updated) {
    final i = _bookings.indexWhere((x) => x.pnr == updated.pnr);
    _bookings[i] = updated;
    _save();
    notifyListeners();
  }
}
