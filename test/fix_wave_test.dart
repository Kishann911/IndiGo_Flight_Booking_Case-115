import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/data/sample_data.dart';
import 'package:indigo_flight_booking/main.dart';
import 'package:indigo_flight_booking/models/models.dart';
import 'package:indigo_flight_booking/screens/booking_confirmation_screen.dart';
import 'package:indigo_flight_booking/screens/checkin_screen.dart';
import 'package:indigo_flight_booking/screens/flight_detail_screen.dart';
import 'package:indigo_flight_booking/widgets/cabin_map.dart';
import 'package:indigo_flight_booking/screens/flight_results_screen.dart';
import 'package:indigo_flight_booking/screens/seat_selection_screen.dart';
import 'package:indigo_flight_booking/state/booking_store.dart';
import 'package:indigo_flight_booking/state/flight_status_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Review fix wave: one focused test per Important item (I1-I5) plus the
/// behaviour-changing minor items.
void main() {
  final now = DateTime(2026, 10, 1, 9, 0);

  Future<AppServices> boot(WidgetTester tester, {Size size = const Size(360, 3000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final s = await AppServices.create(clock: () => now, random: Random(1));
    await tester.pumpWidget(IndigoApp(services: s, showPushBanners: false));
    await tester.pumpAndSettle();
    return s;
  }

  Future<void> push(WidgetTester tester, Widget page) async {
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    await tester.pumpAndSettle();
  }

  Future<BookingStore> bookOne(AppServices s, {required FareFamily family, String? seat}) async {
    final day = DateTime(2026, 10, 11);
    final store = s.bookings;
    store.startDraft([Segment(from: 'DEL', to: 'BOM', date: day)], 1);
    store.chooseFlight(0, SampleData.flightsFor('DEL', 'BOM', day).first, family);
    store.setPassengers(const [Passenger(id: '', firstName: 'Asha', lastName: 'Rao', age: 30)]);
    if (seat != null) store.setSeat(0, store.draft!.passengers.single.id, seat);
    return store;
  }

  group('I1 chronology of later segments', () {
    final day = DateTime(2026, 10, 8);

    testWidgets('same-day DEL->BOM, BOM->BLR hides flights departing < 60 min after arrival', (tester) async {
      final s = await boot(tester);
      final first = SampleData.flightsFor('DEL', 'BOM', day)
          .reduce((a, b) => a.arrival.isAfter(b.arrival) ? a : b);
      final second = SampleData.flightsFor('BOM', 'BLR', day);
      final minDep = first.arrival.add(const Duration(minutes: 60));
      final early = second.where((f) => f.departure.isBefore(minDep)).toList();
      final ok = second.where((f) => !f.departure.isBefore(minDep)).toList();
      expect(early, isNotEmpty, reason: 'precondition: the sample day has flights that must be hidden');

      s.bookings.startDraft([
        Segment(from: 'DEL', to: 'BOM', date: day),
        Segment(from: 'BOM', to: 'BLR', date: day),
      ], 1);
      s.bookings.chooseFlight(0, first, FareFamily.lite);
      await push(tester, const FlightResultsScreen(segIndex: 1));

      for (final f in early) {
        expect(find.byKey(ValueKey('flight-${f.id}'), skipOffstage: false), findsNothing, reason: f.id);
      }
      for (final f in ok) {
        expect(find.byKey(ValueKey('flight-${f.id}'), skipOffstage: false), findsOneWidget, reason: f.id);
      }
      expect(find.text('Only flights departing ≥ 60 min after your previous arrival are shown.'), findsOneWidget);
    });

    testWidgets('shows an empty state when nothing qualifies', (tester) async {
      final s = await boot(tester);
      // Second leg one day earlier than the first arrival is impossible; use same day with a
      // previous flight that lands after every BOM->BLR departure.
      final second = SampleData.flightsFor('BOM', 'BLR', day);
      final lastDep = second.map((f) => f.departure).reduce((a, b) => a.isAfter(b) ? a : b);
      final prev = Flight(
        id: 'late-prev',
        baseFare: 4000,
        legs: [
          FlightLeg(
            flightNo: '6E 9001',
            from: 'DEL',
            to: 'BOM',
            departure: lastDep,
            arrival: lastDep.add(const Duration(hours: 2)),
          ),
        ],
      );
      s.bookings.startDraft([
        Segment(from: 'DEL', to: 'BOM', date: day),
        Segment(from: 'BOM', to: 'BLR', date: day),
      ], 1);
      s.bookings.chooseFlight(0, prev, FareFamily.lite);
      await push(tester, const FlightResultsScreen(segIndex: 1));
      expect(find.text('No flights found'), findsOneWidget);
      expect(find.textContaining('another date'), findsOneWidget);
    });
  });

  group('I2 new bookings are tracked', () {
    testWidgets('confirmDraft registers every leg with FlightStatusService', (tester) async {
      final s = await boot(tester);
      final store = await bookOne(s, family: FareFamily.classic);
      final flight = store.draft!.flights.single!;
      expect(s.flightStatus.tracking(flight.legs.first.flightNo), isNull);
      store.confirmDraft();
      for (final leg in flight.legs) {
        expect(s.flightStatus.tracking(leg.flightNo, date: leg.departure), isNotNull, reason: leg.flightNo);
      }
      // ...so a simulated delay now works and pushes a notification.
      final no = flight.legs.first.flightNo;
      expect(s.flightStatus.simulateDelay(no, 30, date: flight.legs.first.departure), isTrue);
    });
  });

  group('I3 advance-purchase pricing is visible', () {
    testWidgets('detail screen shows the discount line and the full table', (tester) async {
      final s = await boot(tester);
      final date = DateTime(2026, 11, 4); // 34 days ahead of 1 Oct
      s.bookings.startDraft([Segment(from: 'DEL', to: 'BOM', date: date)], 1);
      final flight = SampleData.flightsFor('DEL', 'BOM', date).first;
      await push(tester, FlightDetailScreen(segIndex: 0, flight: flight));
      expect(find.text('Booked 34 days ahead · 15% advance-purchase discount applied'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('pricing-table-toggle')));
      await tester.tap(find.byKey(const ValueKey('pricing-table-toggle')));
      await tester.pumpAndSettle();
      expect(find.textContaining('×0.85'), findsOneWidget);
      expect(find.textContaining('×1.30'), findsOneWidget);
    });

    testWidgets('late booking shows a surcharge line', (tester) async {
      final s = await boot(tester);
      final date = DateTime(2026, 10, 3);
      s.bookings.startDraft([Segment(from: 'DEL', to: 'BOM', date: date)], 1);
      final flight = SampleData.flightsFor('DEL', 'BOM', date).first;
      await push(tester, FlightDetailScreen(segIndex: 0, flight: flight));
      expect(find.text('Booked 2 days ahead · 30% late-booking surcharge'), findsOneWidget);
    });
  });

  group('I4 check-in does not bypass seat fees', () {
    late AppServices s;
    var t = now;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      t = now;
      s = await AppServices.create(clock: () => t, random: Random(1));
    });

    test('K7Q2ZP (Classic, 14C) may move to standard or middle seats, never to row 1', () {
      final b = s.bookings.byPnr('K7Q2ZP')!;
      final pid = b.passengers.single.id;
      final cabin = {for (final x in s.bookings.cabinFor(b.segments.single.flight, excludePnr: 'K7Q2ZP')) x.id: x};
      expect(s.bookings.checkIn('K7Q2ZP', 0, pid, '1A'), isFalse, reason: 'XL seat carries a fee');
      expect(s.bookings.checkIn('K7Q2ZP', 0, pid, '2A'), isFalse, reason: 'front seat carries a fee');
      expect(s.bookings.byPnr('K7Q2ZP')!.isCheckedIn(0, pid), isFalse);
      final middle = cabin.values.firstWhere((x) => !x.occupied && x.tier == SeatTier.standardMiddle && x.row > 14);
      expect(s.bookings.checkIn('K7Q2ZP', 0, pid, middle.id), isTrue);
      expect(s.bookings.byPnr('K7Q2ZP')!.segments.single.seats[pid], middle.id);
    });

    test('a booking without a seat only gets standard tiers at check-in', () async {
      final store = await bookOne(s, family: FareFamily.classic);
      final b = store.confirmDraft();
      final pid = b.passengers.single.id;
      t = b.departure.subtract(const Duration(hours: 5));
      final cabin = store.cabinFor(b.segments.single.flight, excludePnr: b.pnr);
      final xl = cabin.firstWhere((x) => !x.occupied && x.tier == SeatTier.xl);
      expect(store.checkIn(b.pnr, 0, pid, xl.id), isFalse);
      final std = cabin.firstWhere((x) => !x.occupied && x.tier == SeatTier.standard);
      expect(store.checkIn(b.pnr, 0, pid, std.id), isTrue);
    });

    test('booked paid seat: may keep it or move to a cheaper/equal one', () async {
      final store = await bookOne(s, family: FareFamily.classic, seat: '2A'); // front, Rs 449
      final b = store.confirmDraft();
      final pid = b.passengers.single.id;
      t = b.departure.subtract(const Duration(hours: 5));
      expect(store.checkIn(b.pnr, 0, pid, '1A'), isFalse, reason: 'XL is dearer than the booked front seat');
      expect(store.checkIn(b.pnr, 0, pid, null), isTrue, reason: 'keeps the booked seat');
    });

    test('fare total is unchanged by a check-in seat change', () {
      final b = s.bookings.byPnr('K7Q2ZP')!;
      final pid = b.passengers.single.id;
      final cabin = s.bookings.cabinFor(b.segments.single.flight, excludePnr: 'K7Q2ZP');
      final free = cabin.firstWhere((x) => !x.occupied && x.tier == SeatTier.standard && x.id != '14C').id;
      expect(s.bookings.checkIn('K7Q2ZP', 0, pid, free), isTrue);
      expect(s.bookings.byPnr('K7Q2ZP')!.fare, b.fare);
    });
  });

  group('I5 baggage route', () {
    test('a DEL->BOM->DEL round trip bag shows DEL -> BOM with scans at BOM', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await AppServices.create(clock: () => now, random: Random(1));
      final out = SampleData.flightsFor('DEL', 'BOM', DateTime(2026, 10, 11)).first;
      final back = SampleData.flightsFor('BOM', 'DEL', DateTime(2026, 10, 14)).first;
      s.bookings.startDraft([
        Segment(from: 'DEL', to: 'BOM', date: DateTime(2026, 10, 11)),
        Segment(from: 'BOM', to: 'DEL', date: DateTime(2026, 10, 14)),
      ], 1);
      s.bookings.chooseFlight(0, out, FareFamily.classic);
      s.bookings.chooseFlight(1, back, FareFamily.classic);
      s.bookings.setPassengers(const [Passenger(id: '', firstName: 'Asha', lastName: 'Rao', age: 30)]);
      final b = s.bookings.confirmDraft();
      expect(b.to, 'DEL', reason: 'precondition: booking.to is the round-trip origin');
      final bag = s.baggage.ensureBagsForBooking(b).single;
      expect(bag.from, 'DEL');
      expect(bag.to, 'BOM');
      expect(s.baggage.locationFor(bag, BagScanStage.unloadedAtDestination), contains('BOM'));
      expect(s.baggage.locationFor(bag, BagScanStage.onBelt), contains('BOM'));
    });
  });

  group('minor fixes', () {
    test('tracking is keyed by flight number and date', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = FlightStatusService(clock: () => now, eventProbability: 0);
      final d1 = DateTime(2026, 10, 11, 8), d2 = DateTime(2026, 10, 14, 8);
      svc.trackingFor('6E 100', d1, d1.add(const Duration(hours: 2)));
      svc.trackingFor('6E 100', d2, d2.add(const Duration(hours: 2)));
      expect(svc.tracked.length, 2);
      expect(svc.simulateDelay('6E 100', 30, date: d2), isTrue);
      expect(svc.tracking('6E 100', date: d1)!.delayMinutes, 0);
      expect(svc.tracking('6E 100', date: d2)!.delayMinutes, 30);
      expect(svc.tracking('6E 100')!.scheduledDeparture, d1, reason: 'no date: earliest');
      svc.dispose();
    });

    test('cancel: Classic refunds 0 after departure; blocked once anyone has checked in', () async {
      SharedPreferences.setMockInitialValues({});
      var t = now;
      final s = await AppServices.create(clock: () => t, random: Random(1));
      final b = s.bookings.byPnr('K7Q2ZP')!;
      expect(s.bookings.cancelBlockedReason('K7Q2ZP'), isNull);
      t = b.departure.add(const Duration(minutes: 5));
      expect(s.bookings.refundQuote('K7Q2ZP'), 0);

      t = now;
      expect(s.bookings.checkIn('K7Q2ZP', 0, b.passengers.single.id, null), isTrue);
      expect(s.bookings.cancelBlockedReason('K7Q2ZP'), isNotNull);
      expect(s.bookings.cancel('K7Q2ZP'), 0);
      expect(s.bookings.byPnr('K7Q2ZP')!.isCancelled, isFalse);
    });

    test('an untouched, departed sample booking is re-seeded relative to now', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await AppServices.create(clock: () => now, random: Random(1));
      await first.bookings.flush();
      final later = now.add(const Duration(days: 5));
      final s = await AppServices.create(clock: () => later, random: Random(1));
      final b = s.bookings.byPnr('K7Q2ZP')!;
      expect(b.departure.isAfter(later), isTrue);
      expect(s.bookings.checkIn('K7Q2ZP', 0, b.passengers.single.id, null), isTrue);
    });

    test('a changed (cancelled) sample booking is not re-seeded', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await AppServices.create(clock: () => now, random: Random(1));
      first.bookings.cancel('K7Q2ZP');
      await first.bookings.flush();
      final s = await AppServices.create(clock: () => now.add(const Duration(days: 5)), random: Random(1));
      expect(s.bookings.byPnr('K7Q2ZP')!.isCancelled, isTrue);
    });

    testWidgets('Skip on the seat screen keeps seats already chosen', (tester) async {
      final s = await boot(tester, size: const Size(360, 2400));
      final store = await bookOne(s, family: FareFamily.classic, seat: '12A');
      final pid = store.draft!.passengers.single.id;
      await push(tester, const SeatSelectionScreen(segIndex: 0));
      await tester.ensureVisible(find.byKey(const ValueKey('seat-skip')));
      await tester.tap(find.byKey(const ValueKey('seat-skip')));
      await tester.pumpAndSettle();
      expect(store.draft!.seatFor(0, pid), '12A');
    });

    testWidgets('Web check-in from the confirmation prefills PNR and last name', (tester) async {
      final s = await boot(tester, size: const Size(360, 2400));
      final store = await bookOne(s, family: FareFamily.classic);
      final b = store.confirmDraft();
      await push(tester, BookingConfirmationScreen(pnr: b.pnr));
      await tester.ensureVisible(find.byKey(const ValueKey('go-web-checkin')));
      await tester.tap(find.byKey(const ValueKey('go-web-checkin')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(find.byKey(const ValueKey('checkin-pnr'))).controller!.text, b.pnr);
      expect(tester.widget<TextFormField>(find.byKey(const ValueKey('checkin-lastname'))).controller!.text, 'Rao');
    });

    testWidgets('the in-app push banner says (simulated)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final s = await AppServices.create(clock: () => now, random: Random(1));
      await tester.pumpWidget(IndigoApp(services: s));
      await tester.pumpAndSettle();
      s.notifications.push(title: 'Hello', body: 'World', kind: NotificationKind.booking);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('(simulated) Hello'), findsOneWidget);
    });
  
    testWidgets('CabinMap uses 32 px seats under 380 px and fits without horizontal scroll', (tester) async {
      await boot(tester, size: const Size(360, 2400));
      await push(
        tester,
        Scaffold(body: SingleChildScrollView(child: CabinMap(seats: CabinLayout.build(), onTap: (_) {}))),
      );
      expect(tester.getSize(find.byKey(const ValueKey('seat-1A'))).width, 32);
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable).last);
      expect(scroll.position.maxScrollExtent, 0);
    });

    testWidgets('check-in map locks fee seats and explains why', (tester) async {
      final s = await boot(tester, size: const Size(390, 2600));
      await push(tester, const CheckInScreen());
      await tester.enterText(find.byKey(const ValueKey('checkin-pnr')), 'K7Q2ZP');
      await tester.enterText(find.byKey(const ValueKey('checkin-lastname')), 'Ojha');
      await tester.tap(find.byKey(const ValueKey('checkin-find')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('change-seat-pax-kishan')));
      await tester.tap(find.byKey(const ValueKey('change-seat-pax-kishan')));
      await tester.pumpAndSettle();
      final pid = s.bookings.byPnr('K7Q2ZP')!.passengers.single.id;
      await tester.tap(find.byKey(const ValueKey('seat-1B')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Fee applies — choose paid seats while booking'), findsWidgets);
      await tester.ensureVisible(find.byKey(const ValueKey('checkin-submit')));
      await tester.tap(find.byKey(const ValueKey('checkin-submit')));
      await tester.pumpAndSettle();
      expect(s.bookings.byPnr('K7Q2ZP')!.segments.single.seats[pid], '14C', reason: 'row 1 never selected');
    });
  });
}
