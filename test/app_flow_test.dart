import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/data/sample_data.dart';
import 'package:indigo_flight_booking/main.dart';
import 'package:indigo_flight_booking/models/models.dart';
import 'package:indigo_flight_booking/screens/boarding_pass_screen.dart';
import 'package:indigo_flight_booking/screens/booking_confirmation_screen.dart';
import 'package:indigo_flight_booking/screens/extras_screen.dart';
import 'package:indigo_flight_booking/screens/flight_detail_screen.dart';
import 'package:indigo_flight_booking/screens/flight_results_screen.dart';
import 'package:indigo_flight_booking/screens/passenger_details_screen.dart';
import 'package:indigo_flight_booking/screens/seat_selection_screen.dart';
import 'package:indigo_flight_booking/screens/trip_summary_screen.dart';
import 'package:indigo_flight_booking/state/booking_store.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end journeys through the real app (HomeShell), with mock
/// SharedPreferences, an injected clock and no periodic timers.
void main() {
  final now = DateTime(2026, 10, 1, 9, 0);

  Future<AppServices> boot(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final s = await AppServices.create(clock: () => now, random: Random(1));
    await tester.pumpWidget(IndigoApp(services: s, showPushBanners: false));
    await tester.pumpAndSettle();
    return s;
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> tab(WidgetTester tester, String label) async {
    final nav = find.byType(NavigationBar).evaluate().isNotEmpty
        ? find.byType(NavigationBar)
        : find.byType(NavigationRail);
    await tester.tap(find.descendant(of: nav, matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  testWidgets('booking journey: search -> ... -> confirm -> PNR -> My Trips (wide surface)', (tester) async {
    final s = await boot(tester, const Size(1280, 1800));

    // 1. Search DEL -> BOM (the defaults) and go to the results list.
    await tapVisible(tester, find.byKey(const ValueKey('search-button')));
    expect(find.byType(FlightResultsScreen), findsOneWidget);
    final seg = s.bookings.draft!.segments.single;
    expect([seg.from, seg.to], ['DEL', 'BOM']);

    // 2. Results -> detail.
    final flight = SampleData.flightsFor(seg.from, seg.to, seg.date).first;
    await tapVisible(tester, find.byKey(ValueKey('flight-${flight.id}')));
    expect(find.byType(FlightDetailScreen), findsOneWidget);

    // 3. Pick Classic -> passenger form.
    await tapVisible(tester, find.byKey(const ValueKey('select-classic')));
    expect(find.byType(PassengerDetailsScreen), findsOneWidget);
    expect(s.bookings.draft!.families[0], FareFamily.classic);

    // 4. Passenger form -> seat map.
    await tester.enterText(find.byKey(const ValueKey('pax-0-first')), 'Asha');
    await tester.enterText(find.byKey(const ValueKey('pax-0-last')), 'Rao');
    await tester.enterText(find.byKey(const ValueKey('pax-0-age')), '31');
    await tapVisible(tester, find.byKey(const ValueKey('passengers-continue')));
    expect(find.byType(SeatSelectionScreen), findsOneWidget);

    // 5. Choose a free standard seat.
    final free = s.bookings
        .cabinFor(flight)
        .firstWhere((x) => !x.occupied && x.tier == SeatTier.standard);
    await tapVisible(tester, find.byKey(ValueKey('seat-${free.id}')));
    final pid = s.bookings.draft!.passengers.single.id;
    expect(s.bookings.draft!.seatFor(0, pid), free.id);
    await tapVisible(tester, find.byKey(const ValueKey('seat-continue')));
    expect(find.byType(ExtrasScreen), findsOneWidget);

    // 6. Extras: add priority boarding.
    await tapVisible(tester, find.byKey(const ValueKey('addon-priorityBoarding')));
    expect(s.bookings.draft!.hasAddOn(AddOnType.priorityBoarding), isTrue);
    await tapVisible(tester, find.byKey(const ValueKey('extras-continue')));
    expect(find.byType(TripSummaryScreen), findsOneWidget);

    // 7. Summary -> confirm (demo, no payment).
    final quote = s.bookings.draftQuote;
    expect(quote.addOnCharges, 299);
    await tapVisible(tester, find.byKey(const ValueKey('confirm-booking')));
    expect(find.byType(BookingConfirmationScreen), findsOneWidget);

    // 8. The PNR is shown and matches the stored booking.
    final created = s.bookings.bookings.firstWhere((b) => b.pnr != SampleData.samplePnr);
    expect(created.pnr, matches(RegExp(r'^[A-HJ-NP-Z2-9]{6}$')));
    expect(created.fare.total, quote.total);
    expect(created.segments.single.seats[pid], free.id);
    expect(created.addOns, {AddOnType.priorityBoarding});
    expect(tester.widget<SelectableText>(find.byKey(const ValueKey('confirmed-pnr'))).data, created.pnr);
    expect(find.textContaining('no payment'), findsWidgets);

    // 9. The booking is persisted and appears in My Trips.
    final reloaded = BookingStore(clock: () => now);
    await tester.runAsync(() async {
      await s.bookings.flush();
      await reloaded.load();
    });
    expect(reloaded.byPnr(created.pnr), isNotNull);

    await tapVisible(tester, find.text('Go to My Trips'));
    expect(find.byKey(ValueKey('trip-${created.pnr}')), findsOneWidget);
    expect(find.byKey(const ValueKey('trip-K7Q2ZP')), findsOneWidget);
  });

  testWidgets('check-in journey: seeded PNR K7Q2ZP / Ojha -> boarding pass with QR and seat 14C (phone)',
      (tester) async {
    final s = await boot(tester, const Size(390, 844));
    await tab(tester, 'Check-in');
    await tester.enterText(find.byKey(const ValueKey('checkin-pnr')), 'K7Q2ZP');
    await tester.enterText(find.byKey(const ValueKey('checkin-lastname')), 'Ojha');
    await tapVisible(tester, find.byKey(const ValueKey('checkin-find')));
    expect(find.byKey(const ValueKey('checkin-window')), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('checkin-submit')));

    expect(find.byType(BoardingPassScreen), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('14C'), findsOneWidget);
    expect(s.bookings.byPnr('K7Q2ZP')!.isCheckedIn(0, 'pax-kishan'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
