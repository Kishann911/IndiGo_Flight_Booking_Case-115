import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/data/sample_data.dart';
import 'package:indigo_flight_booking/logic/formatters.dart';
import 'package:indigo_flight_booking/logic/pricing.dart';
import 'package:indigo_flight_booking/main.dart';
import 'package:indigo_flight_booking/models/models.dart';
import 'package:indigo_flight_booking/screens/fare_calendar_screen.dart';
import 'package:indigo_flight_booking/screens/flight_detail_screen.dart';
import 'package:indigo_flight_booking/screens/flight_results_screen.dart';
import 'package:indigo_flight_booking/screens/passenger_details_screen.dart';
import 'package:indigo_flight_booking/widgets/fare_family_card.dart';
import 'package:indigo_flight_booking/widgets/journey_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 1, 9, 0);
  final depDay = DateTime(2026, 10, 8); // default search date: today + 7

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

  Future<void> search(WidgetTester tester) => tapVisible(tester, find.byKey(const ValueKey('search-button')));

  testWidgets('search -> results list shows times, stops, duration and price', (tester) async {
    final s = await boot(tester, const Size(360, 780));
    expect(find.byType(JourneyProgress), findsOneWidget);
    await search(tester);
    expect(find.byType(FlightResultsScreen), findsOneWidget);
    expect(s.bookings.draft!.segments.single.from, 'DEL');
    expect(s.bookings.draft!.segments.single.to, 'BOM');

    final flights = SampleData.flightsFor('DEL', 'BOM', depDay);
    expect(flights.length, greaterThanOrEqualTo(4));
    final first = flights.first;
    final firstCard = find.byKey(ValueKey('flight-${first.id}'));
    expect(firstCard, findsOneWidget);
    expect(find.descendant(of: firstCard, matching: find.text(Fmt.time(first.departure))), findsOneWidget);
    expect(find.descendant(of: firstCard, matching: find.text(Fmt.time(first.arrival))), findsOneWidget);
    expect(find.descendant(of: firstCard, matching: find.text(Fmt.duration(first.totalDuration))), findsOneWidget);
    expect(find.descendant(of: firstCard, matching: find.text(Fmt.inr(PricingEngine.dynamicBaseFare(first, now)))),
        findsOneWidget);
    expect(find.byType(JourneyProgress), findsOneWidget);

    // Stops text is present for every listed flight (Non-stop or "N stop via ...").
    for (final f in flights) {
      final t = find.byKey(ValueKey('stops-${f.id}'));
      await tester.scrollUntilVisible(t, 200, scrollable: find.byType(Scrollable).first);
      final text = (tester.widget<Text>(t)).data!;
      expect(text, f.stops == 0 ? 'Non-stop' : contains('via ${f.viaAirports.first}'));
    }
    // Sorting by cheapest puts the lowest fare first.
    await tester.scrollUntilVisible(find.byKey(const ValueKey('sort-cheapest')), -400,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('sort-cheapest')));
    await tester.pumpAndSettle();
    expect(find.text('Lowest fare'), findsWidgets);
  });

  testWidgets('fare calendar shows fares and highlights the cheapest day', (tester) async {
    await boot(tester, const Size(360, 780));
    await tapVisible(tester, find.byKey(const ValueKey('date-0')));
    expect(find.byType(FareCalendarScreen), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);

    final fares = <int, int>{};
    for (var day = 1; day <= 31; day++) {
      final f = find.byKey(ValueKey('cal-fare-10-$day'));
      if (f.evaluate().isEmpty) continue;
      fares[day] = PricingEngine.lowestFareForDay('DEL', 'BOM', DateTime(2026, 10, day), now);
      expect(tester.widget<Text>(f).data, Fmt.inr(fares[day]!));
    }
    expect(fares.length, 31); // today is 1 Oct, so all of October is listed
    final min = fares.values.reduce((a, b) => a < b ? a : b);
    final scheme = Theme.of(tester.element(find.byType(FareCalendarScreen))).colorScheme;
    Color? bg(int day) => tester.widget<Material>(find.byKey(ValueKey('cal-day-10-$day'))).color;
    final cheapestDays = fares.entries.where((e) => e.value == min).map((e) => e.key).toList();
    for (final day in fares.keys) {
      if (day == 8) continue; // the selected date uses the primary colour
      expect(bg(day) == scheme.tertiaryContainer, cheapestDays.contains(day), reason: 'day $day');
    }

    // Tapping a day returns it to the search screen.
    await tester.tap(find.byKey(const ValueKey('cal-day-10-20')));
    await tester.pumpAndSettle();
    expect(find.byType(FareCalendarScreen), findsNothing);
    expect(find.text(Fmt.weekdayDayMonth(DateTime(2026, 10, 20))), findsOneWidget);
  });

  testWidgets('detail shows 3 fare families side by side on wide screens', (tester) async {
    await boot(tester, const Size(1200, 900));
    await search(tester);
    final flight = SampleData.flightsFor('DEL', 'BOM', depDay).first;
    await tapVisible(tester, find.byKey(ValueKey('flight-${flight.id}')));
    expect(find.byType(FlightDetailScreen), findsOneWidget);
    expect(find.byType(FareFamilyCard), findsNWidgets(3));
    final tops = [for (final f in FareFamily.values) tester.getTopLeft(find.byKey(ValueKey('fare-card-${f.name}')))];
    expect(tops[0].dy, tops[1].dy);
    expect(tops[1].dy, tops[2].dy);
    expect(tops[0].dx < tops[1].dx && tops[1].dx < tops[2].dx, isTrue);
    expect(find.byKey(const ValueKey('addon-note')), findsOneWidget);
    expect(find.byKey(const ValueKey('baggage-lite')), findsOneWidget);
    expect(find.byKey(const ValueKey('total-duration')), findsOneWidget);
    expect(find.text(Fmt.inr(PricingEngine.dynamicBaseFare(flight, now) + 800)), findsOneWidget);
  });

  testWidgets('phone detail lays out 3 scrollable fare cards without overflow', (tester) async {
    await boot(tester, const Size(360, 780));
    await search(tester);
    final flight = SampleData.flightsFor('DEL', 'BOM', depDay).first;
    await tapVisible(tester, find.byKey(ValueKey('flight-${flight.id}')));
    expect(find.byType(FareFamilyCard, skipOffstage: false), findsNWidgets(3));
    await tester.ensureVisible(find.byKey(const ValueKey('fare-columns')));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const ValueKey('fare-columns')), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('select-flex')), findsOneWidget);
    expect(find.byKey(const ValueKey('addon-note')), findsOneWidget);
  });

  testWidgets('selecting Classic updates the draft and moves to passenger details', (tester) async {
    final s = await boot(tester, const Size(1200, 900));
    await search(tester);
    final flight = SampleData.flightsFor('DEL', 'BOM', depDay).first;
    await tapVisible(tester, find.byKey(ValueKey('flight-${flight.id}')));
    expect(s.bookings.draft!.families[0], isNull);

    await tapVisible(tester, find.byKey(const ValueKey('select-classic')));
    final d = s.bookings.draft!;
    expect(d.flights[0], flight);
    expect(d.families[0], FareFamily.classic);
    expect(find.byType(PassengerDetailsScreen), findsOneWidget);
  });

  testWidgets('multi-city adds segments and continues to the next segment after choosing', (tester) async {
    final s = await boot(tester, const Size(360, 780));
    await tester.tap(find.text('Multi-city'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('date-1')), findsOneWidget);
    await search(tester);
    expect(s.bookings.draft!.segmentCount, 2);
    final seg = s.bookings.draft!.segments[0];
    final flight = SampleData.flightsFor(seg.from, seg.to, seg.date).first;
    await tapVisible(tester, find.byKey(ValueKey('flight-${flight.id}')));
    await tapVisible(tester, find.byKey(const ValueKey('select-lite')));
    expect(find.byType(FlightResultsScreen), findsOneWidget);
    expect(find.text('Flight 2 of 2'), findsOneWidget);
  });
}
