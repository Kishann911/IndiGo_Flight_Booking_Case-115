import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/data/sample_data.dart';
import 'package:indigo_flight_booking/logic/pricing.dart';
import 'package:indigo_flight_booking/models/models.dart';
import 'package:indigo_flight_booking/state/booking_store.dart';
import 'package:indigo_flight_booking/state/notification_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  DateTime clock() => now;

  Future<(BookingStore, NotificationStore)> makeStore() async {
    final n = NotificationStore(clock: clock, random: Random(1));
    final s = BookingStore(notifications: n, clock: clock, random: Random(7));
    await n.load();
    await s.load();
    return (s, n);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 1, 9, 0);
  });

  Future<Booking> bookOne(BookingStore s) async {
    final day = DateTime(2026, 10, 11);
    s.startDraft([Segment(from: 'DEL', to: 'BOM', date: day)], 1);
    final flight = SampleData.flightsFor('DEL', 'BOM', day).first;
    s.chooseFlight(0, flight, FareFamily.classic);
    s.setPassengers(const [Passenger(id: '', firstName: 'Asha', lastName: 'Rao', age: 30)]);
    final pid = s.draft!.passengers.single.id;
    expect(pid, isNotEmpty);
    s.setSeat(0, pid, '12A');
    s.setMeal(0, pid, SampleData.meals.first.id);
    s.toggleAddOn(AddOnType.priorityBoarding);
    return s.confirmDraft();
  }

  test('sample booking is seeded on first launch', () async {
    final (s, _) = await makeStore();
    expect(s.bookings.map((b) => b.pnr), contains('K7Q2ZP'));
    final b = s.byPnr('K7Q2ZP')!;
    expect(b.passengers.single.fullName, 'Kishan Ojha');
    expect(b.segments.single.family, FareFamily.classic);
    expect(b.segments.single.seats.values.single, '14C');
    expect(b.from, 'DEL');
    expect(b.to, 'BOM');
  });

  test('sample booking is seeded once only', () async {
    final (s, _) = await makeStore();
    s.cancel('K7Q2ZP');
    await s.flush();
    await s.load(); // reloading the same store must not duplicate
    final (s2, _) = await makeStore();
    expect(s.bookings.where((b) => b.pnr == 'K7Q2ZP').length, 1);
    expect(s2.bookings.where((b) => b.pnr == 'K7Q2ZP').length, 1);
    expect(s2.byPnr('K7Q2ZP')!.isCancelled, isTrue);
  });

  test('draft quote reflects choices', () async {
    final (s, _) = await makeStore();
    final day = DateTime(2026, 10, 11);
    s.startDraft([Segment(from: 'DEL', to: 'BOM', date: day)], 2);
    expect(s.draft!.passengerCount, 2);
    expect(s.draft!.allFlightsChosen, isFalse);
    final f = SampleData.flightsFor('DEL', 'BOM', day).first;
    s.chooseFlight(0, f, FareFamily.lite);
    expect(s.draft!.allFlightsChosen, isTrue);
    final base = PricingEngine.dynamicBaseFare(f, now);
    expect(s.draftQuote.baseFare, base * 2);
    s.toggleAddOn(AddOnType.extraBaggage5kg);
    s.toggleAddOn(AddOnType.extraBaggage10kg);
    expect(s.draft!.addOns, {AddOnType.extraBaggage10kg}, reason: 'baggage add-ons are exclusive');
    expect(s.draftQuote.addOnCharges, 3400);
    s.toggleAddOn(AddOnType.extraBaggage10kg);
    expect(s.draft!.addOns, isEmpty);
  });

  test('two passengers cannot hold the same seat in a draft', () async {
    final (s, _) = await makeStore();
    final day = DateTime(2026, 10, 11);
    s.startDraft([Segment(from: 'DEL', to: 'BOM', date: day)], 2);
    s.chooseFlight(0, SampleData.flightsFor('DEL', 'BOM', day).first, FareFamily.lite);
    s.setPassengers(const [
      Passenger(id: 'a', firstName: 'A', lastName: 'One', age: 30),
      Passenger(id: 'b', firstName: 'B', lastName: 'Two', age: 31),
    ]);
    s.setSeat(0, 'a', '7A');
    s.setSeat(0, 'b', '7A');
    expect(s.draft!.seats[0], {'b': '7A'});
  });

  test('draft → confirm persists and reloads', () async {
    final (s, n) = await makeStore();
    final b = await bookOne(s);
    expect(s.draft, isNull);
    expect(s.byPnr(b.pnr), isNotNull);
    expect(b.fare.total, greaterThan(0));
    expect(b.fare.seatFees, 799);
    expect(b.fare.mealCharges, 0);
    expect(b.fare.addOnCharges, 299);
    expect(n.items.first.kind, NotificationKind.booking);
    expect(n.items.first.body, contains(b.pnr));
    await s.flush();

    final (s2, _) = await makeStore();
    final r = s2.byPnr(b.pnr)!;
    expect(r.fare, b.fare);
    expect(r.passengers.single.lastName, 'Rao');
    expect(r.segments.single.seats.values.single, '12A');
    expect(r.segments.single.flight.id, b.segments.single.flight.id);
    expect(r.segments.single.flight.departure, b.segments.single.flight.departure);
    expect(r.addOns, {AddOnType.priorityBoarding});
  });

  test('confirming an incomplete draft throws', () async {
    final (s, _) = await makeStore();
    s.startDraft([Segment(from: 'DEL', to: 'BOM', date: DateTime(2026, 10, 11))], 1);
    expect(() => s.confirmDraft(), throwsStateError);
  });

  test('PNR format: 6 chars of A–Z / 2–9, unique', () async {
    final (s, _) = await makeStore();
    final pnrs = <String>{};
    for (var i = 0; i < 20; i++) {
      final b = await bookOne(s);
      expect(b.pnr, matches(RegExp(r'^[A-Z2-9]{6}$')));
      pnrs.add(b.pnr);
    }
    expect(pnrs.length, 20);
  });

  test('findByPnr is case-insensitive on PNR and last name', () async {
    final (s, _) = await makeStore();
    expect(s.findByPnr('k7q2zp', 'OJHA')?.pnr, 'K7Q2ZP');
    expect(s.findByPnr(' K7Q2ZP ', 'ojha ')?.pnr, 'K7Q2ZP');
    expect(s.findByPnr('K7Q2ZP', 'Sharma'), isNull);
    expect(s.findByPnr('ZZZZZZ', 'Ojha'), isNull);
  });

  test('check-in succeeds inside the window', () async {
    final (s, _) = await makeStore();
    final b = s.byPnr('K7Q2ZP')!;
    final pid = b.passengers.single.id;
    final cabin = s.cabinFor(b.segments.single.flight, excludePnr: 'K7Q2ZP');
    final free = cabin.firstWhere((x) => !x.occupied && x.id != '14C').id;
    expect(s.checkIn('K7Q2ZP', 0, pid, free), isTrue);
    final after = s.byPnr('K7Q2ZP')!;
    expect(after.isCheckedIn(0, pid), isTrue);
    expect(after.segments.single.seats[pid], free);
  });

  test('check-in rejects an occupied seat', () async {
    final (s, _) = await makeStore();
    final b = s.byPnr('K7Q2ZP')!;
    final pid = b.passengers.single.id;
    final cabin = s.cabinFor(b.segments.single.flight, excludePnr: 'K7Q2ZP');
    final taken = cabin.firstWhere((x) => x.occupied).id;
    expect(s.checkIn('K7Q2ZP', 0, pid, taken), isFalse);
    expect(s.byPnr('K7Q2ZP')!.isCheckedIn(0, pid), isFalse);
  });

  test('check-in auto-assigns a seat when none is given or held', () async {
    final (s, _) = await makeStore();
    final b = await bookOne(s);
    final pid = b.passengers.single.id;
    now = b.departure.subtract(const Duration(hours: 5));
    expect(s.checkIn(b.pnr, 0, pid, null), isTrue);
    expect(s.byPnr(b.pnr)!.segments.single.seats[pid], '12A', reason: 'keeps the booked seat');
  });

  test('check-in rejected outside the window', () async {
    final (s, _) = await makeStore();
    final b = await bookOne(s); // departs 10 days out
    final pid = b.passengers.single.id;
    expect(s.checkIn(b.pnr, 0, pid, null), isFalse);
    now = b.departure.subtract(const Duration(minutes: 30));
    expect(s.checkIn(b.pnr, 0, pid, null), isFalse);
    expect(s.byPnr(b.pnr)!.isCheckedIn(0, pid), isFalse);
  });

  test('check-in rejected for cancelled booking or unknown passenger', () async {
    final (s, _) = await makeStore();
    expect(s.checkIn('K7Q2ZP', 0, 'nobody', null), isFalse);
    final pid = s.byPnr('K7Q2ZP')!.passengers.single.id;
    s.cancel('K7Q2ZP');
    expect(s.checkIn('K7Q2ZP', 0, pid, null), isFalse);
  });

  test('cancel returns the refund and marks the booking cancelled', () async {
    final (s, _) = await makeStore();
    final b = s.byPnr('K7Q2ZP')!;
    final expected = PricingEngine.cancellationRefund(b, now);
    expect(expected, b.fare.total - 2999 - b.fare.addOnCharges);
    expect(s.cancel('K7Q2ZP'), expected);
    expect(s.byPnr('K7Q2ZP')!.status, BookingStatus.cancelled);
    expect(s.cancel('K7Q2ZP'), 0, reason: 'second cancel refunds nothing');
    expect(s.cancel('NOPE22'), 0);
  });

  test('cabinFor marks seats held by other bookings on the same flight', () async {
    final (s, _) = await makeStore();
    final b = s.byPnr('K7Q2ZP')!;
    final flight = b.segments.single.flight;
    final cabin = {for (final seat in s.cabinFor(flight)) seat.id: seat};
    expect(cabin['14C']!.occupied, isTrue);
    final own = {for (final seat in s.cabinFor(flight, excludePnr: 'K7Q2ZP')) seat.id: seat};
    expect(own['14C']!.occupied, isFalse);
    expect(own.length, 180);
  });
}
