import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/data/sample_data.dart';
import 'package:indigo_flight_booking/logic/formatters.dart';
import 'package:indigo_flight_booking/main.dart';
import 'package:indigo_flight_booking/models/models.dart';
import 'package:indigo_flight_booking/screens/booking_confirmation_screen.dart';
import 'package:indigo_flight_booking/screens/extras_screen.dart';
import 'package:indigo_flight_booking/screens/passenger_details_screen.dart';
import 'package:indigo_flight_booking/screens/seat_selection_screen.dart';
import 'package:indigo_flight_booking/screens/trip_summary_screen.dart';
import 'package:indigo_flight_booking/widgets/journey_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 1, 9, 0);

  Future<AppServices> boot(WidgetTester tester, {Size size = const Size(400, 3200), int pax = 2}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final s = await AppServices.create(clock: () => now, random: Random(1));
    await tester.pumpWidget(IndigoApp(services: s, showPushBanners: false));
    await tester.pumpAndSettle();
    return s;
  }

  /// Seeds a complete draft: DEL→BOM in Classic with [pax] passengers.
  void seed(AppServices s, {int pax = 2, FareFamily family = FareFamily.classic}) {
    final day = DateTime(2026, 10, 20);
    final flight = SampleData.flightsFor('DEL', 'BOM', day).first;
    s.bookings
      ..startDraft([Segment(from: 'DEL', to: 'BOM', date: day)], pax)
      ..chooseFlight(0, flight, family)
      ..setPassengers([
        for (var i = 0; i < pax; i++) Passenger(id: '', firstName: i == 0 ? 'Asha' : 'Bina', lastName: 'Rao', age: 30 + i),
      ]);
  }

  Future<void> open(WidgetTester tester, Widget screen) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).push(MaterialPageRoute<void>(builder: (_) => screen));
    await tester.pumpAndSettle();
  }

  testWidgets('passenger validation blocks an empty name, then continues to seats', (tester) async {
    final s = await boot(tester);
    seed(s);
    s.bookings.setPassengers(const []); // fresh, empty forms
    await open(tester, const PassengerDetailsScreen());
    expect(find.byType(JourneyProgress), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('passengers-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Enter first name'), findsWidgets);
    expect(find.byType(SeatSelectionScreen), findsNothing);
    expect(s.bookings.draft!.passengers, isEmpty);

    for (var i = 0; i < 2; i++) {
      await tester.enterText(find.byKey(ValueKey('pax-$i-first')), i == 0 ? 'Asha' : 'Bina');
      await tester.enterText(find.byKey(ValueKey('pax-$i-last')), 'Rao');
      await tester.enterText(find.byKey(ValueKey('pax-$i-age')), '3$i');
    }
    await tester.tap(find.byKey(const ValueKey('passengers-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(SeatSelectionScreen), findsOneWidget);
    expect(s.bookings.draft!.passengers.length, 2);
  });

  testWidgets('passenger form fits a 360 px phone without overflow', (tester) async {
    final s = await boot(tester, size: const Size(360, 3000));
    seed(s, pax: 2);
    s.bookings.setPassengers(const []);
    await open(tester, const PassengerDetailsScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Pick from saved travellers'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('passengers-continue')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved traveller chooser fills the form', (tester) async {
    final s = await boot(tester);
    seed(s, pax: 1);
    s.bookings.setPassengers(const []);
    await open(tester, const PassengerDetailsScreen());
    await tester.tap(find.byKey(const ValueKey('pick-saved-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('saved-${s.profile.me.id}')));
    await tester.pumpAndSettle();
    expect(find.text(s.profile.me.firstName), findsOneWidget);
  });

  testWidgets('seat tap shows price and legroom; occupied seats cannot be selected', (tester) async {
    final s = await boot(tester);
    seed(s);
    await open(tester, const SeatSelectionScreen(segIndex: 0));
    final cabin = s.bookings.cabinFor(s.bookings.draft!.flights[0]!);
    final free = cabin.firstWhere((x) => !x.occupied && x.tier == SeatTier.xl);
    final taken = cabin.firstWhere((x) => x.occupied);

    await tester.tap(find.byKey(ValueKey('seat-${taken.id}')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(s.bookings.draft!.seats[0], isEmpty);
    expect(find.byKey(const ValueKey('seat-info')), findsNothing);

    await tester.tap(find.byKey(ValueKey('seat-${free.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('seat-info')), findsOneWidget);
    expect(find.text('Legroom: Extra legroom, 34–36 in pitch'), findsOneWidget);
    expect(find.text('Price: ${Fmt.inr(799)}'), findsOneWidget);
    final pid = s.bookings.draft!.passengers.first.id;
    expect(s.bookings.draft!.seatFor(0, pid), free.id);
    expect(find.text('Skip (auto-assign at check-in)'), findsOneWidget);
  });

  testWidgets('priority boarding adds Rs 299 x pax to the quote', (tester) async {
    final s = await boot(tester);
    seed(s, pax: 3);
    final before = s.bookings.draftQuote;
    await open(tester, const ExtrasScreen());
    await tester.tap(find.byKey(const ValueKey('addon-priorityBoarding')));
    await tester.pumpAndSettle();
    final after = s.bookings.draftQuote;
    expect(after.addOnCharges - before.addOnCharges, 299 * 3);
    expect(after.total - before.total, 299 * 3);
    expect(find.text('Extras: ${Fmt.inr(299 * 3)}'), findsOneWidget);
    // Classic: complimentary-meal note is shown.
    expect(find.textContaining('complimentary meal'), findsWidgets);
  });

  testWidgets('meal filters narrow the list and a meal can be chosen', (tester) async {
    final s = await boot(tester);
    seed(s, pax: 1);
    await open(tester, const ExtrasScreen());
    expect(find.text('14 meals match'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cuisine-Snacks')));
    await tester.tap(find.byKey(const ValueKey('diet-jain')));
    await tester.pumpAndSettle();
    expect(find.text('2 meals match'), findsOneWidget);
    final pid = s.bookings.draft!.passengers.first.id;
    await tester.tap(find.byKey(ValueKey('meal-0-$pid')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Jain Poha').last);
    await tester.pumpAndSettle();
    expect(s.bookings.draft!.mealFor(0, pid), 'm12');
  });

  testWidgets('summary breakdown lines sum to draftQuote.total; confirm shows PNR', (tester) async {
    final s = await boot(tester);
    seed(s);
    s.bookings.toggleAddOn(AddOnType.priorityBoarding);
    await open(tester, const TripSummaryScreen());
    final q = s.bookings.draftQuote;

    int lineOf(String k) {
      final t = tester.widget<Text>(find.byKey(ValueKey('fare-$k'))).data!;
      return int.parse(t.replaceAll(RegExp(r'[^0-9]'), ''));
    }

    final sum = ['base', 'family', 'seats', 'meals', 'addons', 'taxes'].map(lineOf).reduce((a, b) => a + b);
    expect(lineOf('total'), q.total);
    expect(sum, q.total);
    expect(tester.widget<Text>(find.byKey(const ValueKey('fare-total'))).data, Fmt.inr(q.total));
    expect(find.byKey(const ValueKey('refund-example')), findsOneWidget);
    expect(find.text('Confirm booking (demo — no payment)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-booking')));
    await tester.pumpAndSettle();
    expect(find.byType(BookingConfirmationScreen), findsOneWidget);
    expect(s.bookings.draft, isNull);
    final created = s.bookings.bookings.firstWhere((b) => b.pnr != SampleData.samplePnr);
    expect(created.fare.total, q.total);
    final shown = tester.widget<SelectableText>(find.byKey(const ValueKey('confirmed-pnr'))).data;
    expect(shown, created.pnr);
    expect(find.text('Go to My Trips'), findsOneWidget);
    expect(find.text('Web check-in'), findsOneWidget);
  });

  testWidgets('My Trips lists the seeded booking; read-only summary can cancel with refund', (tester) async {
    final s = await boot(tester, size: const Size(360, 3000));
    await tester.tap(find.text('My Trips').last);
    await tester.pumpAndSettle();
    expect(find.text('PNR K7Q2ZP'), findsOneWidget);
    expect(find.textContaining('Web check-in:'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('trip-K7Q2ZP')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('confirm-booking')), findsNothing);
    final refund = s.bookings.refundQuote('K7Q2ZP');
    await tester.tap(find.byKey(const ValueKey('cancel-booking')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Refund if you cancel now: ${Fmt.inr(refund)}'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancel-confirm')));
    await tester.pumpAndSettle();
    expect(s.bookings.byPnr('K7Q2ZP')!.isCancelled, isTrue);
    expect(find.byKey(const ValueKey('cancelled-note')), findsOneWidget);
  });

  testWidgets('wide layout renders summary and seats without overflow', (tester) async {
    final s = await boot(tester, size: const Size(1280, 1600));
    seed(s);
    await open(tester, const SeatSelectionScreen(segIndex: 0));
    expect(tester.takeException(), isNull);
    await open(tester, const TripSummaryScreen());
    expect(tester.takeException(), isNull);
  });
}
