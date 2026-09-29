import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/main.dart';
import 'package:indigo_flight_booking/models/models.dart';
import 'package:indigo_flight_booking/screens/boarding_pass_screen.dart';
import 'package:indigo_flight_booking/screens/notifications_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 1, 9, 0);

  Future<AppServices> services() async {
    SharedPreferences.setMockInitialValues({});
    return AppServices.create(clock: () => now, random: Random(1));
  }

  Future<void> boot(WidgetTester tester, AppServices s, {Size size = const Size(400, 1600)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(IndigoApp(services: s, showPushBanners: false));
    await tester.pumpAndSettle();
  }

  Future<void> tab(WidgetTester tester, String label) async {
    final nav = find.byType(NavigationBar).evaluate().isNotEmpty ? find.byType(NavigationBar) : find.byType(NavigationRail);
    await tester.tap(find.descendant(of: nav, matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  testWidgets('check-in with seeded PNR shows open window and leads to a boarding pass with QR and seat 14C',
      (tester) async {
    final s = await services();
    await boot(tester, s);
    await tab(tester, 'Check-in');
    await tester.enterText(find.byKey(const ValueKey('checkin-pnr')), 'k7q2zp');
    await tester.enterText(find.byKey(const ValueKey('checkin-lastname')), 'ojha');
    await tester.tap(find.byKey(const ValueKey('checkin-find')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Open'), findsWidgets);
    expect(find.byKey(const ValueKey('checkin-window')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checkin-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(BoardingPassScreen), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('14C'), findsOneWidget);
    expect(find.textContaining('M1OJHA/KISHAN EK7Q2ZP'), findsOneWidget);
    expect(s.bookings.byPnr('K7Q2ZP')!.isCheckedIn(0, 'pax-kishan'), isTrue);
  });

  testWidgets('a wrong PNR shows an error', (tester) async {
    final s = await services();
    await boot(tester, s);
    await tab(tester, 'Check-in');
    await tester.enterText(find.byKey(const ValueKey('checkin-pnr')), 'ZZZZZZ');
    await tester.enterText(find.byKey(const ValueKey('checkin-lastname')), 'ojha');
    await tester.tap(find.byKey(const ValueKey('checkin-find')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('checkin-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('checkin-submit')), findsNothing);
  });

  testWidgets('flight status shows the delay after simulateDelay and a notification appears', (tester) async {
    final s = await services();
    await boot(tester, s);
    await tab(tester, 'Flight Status');
    expect(find.textContaining('simulated real-time'), findsWidgets);
    expect(find.text('On time'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('simulate-delay')));
    await tester.pumpAndSettle();
    expect(find.text('+30 min'), findsOneWidget);
    expect(find.text('Delayed'), findsOneWidget);
    expect(s.notifications.items.any((n) => n.kind == NotificationKind.delay), isTrue);

    await tester.tap(find.byKey(const ValueKey('notification-bell')).hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.textContaining('Flight delayed'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mark-all-read')));
    await tester.pumpAndSettle();
    expect(s.notifications.unread, 0);
  });

  testWidgets('baggage Simulate RFID scan advances one stage', (tester) async {
    final s = await services();
    await boot(tester, s);
    await tester.tap(find.byKey(const ValueKey('baggage-button')).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('6E-RFID-0011523'), findsOneWidget);
    expect(s.baggage.bag('6E-RFID-0011523')!.scans, isEmpty);
    await tester.tap(find.byKey(const ValueKey('scan-6E-RFID-0011523')));
    await tester.pumpAndSettle();
    expect(s.baggage.bag('6E-RFID-0011523')!.stage, BagScanStage.checkedIn);
    await tester.tap(find.byKey(const ValueKey('scan-6E-RFID-0011523')));
    await tester.pumpAndSettle();
    expect(s.baggage.bag('6E-RFID-0011523')!.stage, BagScanStage.securityScreened);
    expect(find.textContaining('Security X-ray 3'), findsOneWidget);
    expect(s.baggage.isAutoScanning, isFalse);
  });

  testWidgets('profile: adding a saved traveller lists them; edit FF number', (tester) async {
    final s = await services();
    await boot(tester, s);
    await tab(tester, 'Profile');
    expect(find.textContaining('not affiliated with InterGlobe Aviation / IndiGo'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-traveller')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('traveller-first')), 'Meera');
    await tester.enterText(find.byKey(const ValueKey('traveller-last')), 'Iyer');
    await tester.enterText(find.byKey(const ValueKey('traveller-age')), '34');
    await tester.tap(find.byKey(const ValueKey('traveller-save')));
    await tester.pumpAndSettle();
    expect(find.text('Meera Iyer'), findsOneWidget);
    expect(s.profile.savedTravellers.any((p) => p.fullName == 'Meera Iyer'), isTrue);

    await tester.tap(find.byKey(const ValueKey('edit-ff')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('ff-field')), 'FF998877');
    await tester.tap(find.byKey(const ValueKey('ff-save')));
    await tester.pumpAndSettle();
    expect(find.text('FF998877'), findsOneWidget);
  });

  testWidgets('screens fit a 360 px phone without overflow', (tester) async {
    final s = await services();
    await boot(tester, s, size: const Size(360, 780));
    for (final t in ['Check-in', 'Flight Status', 'Profile']) {
      await tab(tester, t);
    }
    expect(tester.takeException(), isNull);
  });
}
