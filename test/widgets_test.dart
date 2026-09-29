import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/main.dart';
import 'package:indigo_flight_booking/models/models.dart';
import 'package:indigo_flight_booking/screens/notifications_screen.dart';
import 'package:indigo_flight_booking/theme.dart';
import 'package:indigo_flight_booking/widgets/cabin_map.dart';
import 'package:indigo_flight_booking/widgets/fare_family_card.dart';
import 'package:indigo_flight_booking/widgets/journey_progress.dart';
import 'package:indigo_flight_booking/widgets/price_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 1, 9, 0);

  Future<AppServices> services() async {
    SharedPreferences.setMockInitialValues({});
    return AppServices.create(clock: () => now, random: Random(1));
  }

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('phone shell: NavigationBar with 5 tabs, bell opens notifications', (tester) async {
    await setSize(tester, const Size(360, 780));
    final s = await services();
    expect(s.flightStatus.isRunning, isFalse);
    await tester.pumpWidget(IndigoApp(services: s));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final label in ['Book', 'My Trips', 'Check-in', 'Flight Status', 'Profile']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-bell')).hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
  });

  testWidgets('wide shell uses NavigationRail; a new notification shows a push SnackBar', (tester) async {
    await setSize(tester, const Size(1200, 800));
    final s = await services();
    await tester.pumpWidget(IndigoApp(services: s));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    s.flightStatus.trackingFor('6E 2175', now.add(const Duration(hours: 5)), now.add(const Duration(hours: 7)));
    s.flightStatus.simulateGateChange('6E 2175', '22B');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('push-snackbar')), findsOneWidget);
    expect(find.textContaining('22B'), findsOneWidget);
  });

  testWidgets('CabinMap at 360 px: 180 seats, occupied disabled, taps report seats', (tester) async {
    await setSize(tester, const Size(360, 780));
    final seats = CabinLayout.build(occupied: {'1A', '14C'});
    final tapped = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            CabinMap(
              seats: seats,
              selected: '12A',
              passengerSeats: const {'12A': 'KO'},
              onTap: (s) => tapped.add(s.id),
            ),
            CabinMap.legend(family: FareFamily.flex),
          ]),
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('seat-30F')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('seat-1A')));
    await tester.tap(find.byKey(const ValueKey('seat-1B')));
    await tester.ensureVisible(find.byKey(const ValueKey('seat-14C')));
    await tester.tap(find.byKey(const ValueKey('seat-14C')));
    await tester.tap(find.byKey(const ValueKey('seat-14D')));
    expect(tapped, ['1B', '14D']);
    expect(find.text('KO'), findsOneWidget);
    expect(find.textContaining('Free with Flex'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('JourneyProgress, FareFamilyCard and PriceText render', (tester) async {
    await setSize(tester, const Size(360, 780));
    var selected = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: ListView(children: [
          const JourneyProgress(step: 3),
          FareFamilyCard(family: FareFamily.classic, price: 6250, onSelect: () => selected = true),
          const PriceText(1234567),
        ]),
      ),
    ));
    expect(find.text('STEP 3 OF 6'), findsOneWidget);
    expect(find.bySemanticsLabel(JourneyProgress.labelFor(3)), findsOneWidget);
    expect(find.text('₹6,250'), findsOneWidget);
    expect(find.text('₹12,34,567'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('select-classic')));
    expect(selected, isTrue);
    expect(tester.takeException(), isNull);
  });
}
