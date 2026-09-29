import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/models/models.dart';
import 'package:indigo_flight_booking/state/baggage_service.dart';
import 'package:indigo_flight_booking/state/flight_status_service.dart';
import 'package:indigo_flight_booking/state/notification_store.dart';
import 'package:indigo_flight_booking/state/profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  DateTime clock() => now;
  final dep = DateTime(2026, 10, 1, 12, 0);
  final arr = DateTime(2026, 10, 1, 14, 0);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 1, 6, 0);
  });

  group('NotificationStore', () {
    test('add, unread, markAllRead, persistence', () async {
      final n = NotificationStore(clock: clock, random: Random(1));
      await n.load();
      final incoming = <AppNotification>[];
      final sub = n.incoming.listen(incoming.add);
      n.push(title: 'A', body: 'a', kind: NotificationKind.booking);
      n.push(title: 'B', body: 'b', kind: NotificationKind.gate);
      expect(n.unread, 2);
      expect(n.items.first.title, 'B', reason: 'newest first');
      await Future<void>.delayed(Duration.zero);
      expect(incoming.map((e) => e.title), ['A', 'B']);
      n.markAllRead();
      expect(n.unread, 0);
      await n.flush();
      final n2 = NotificationStore(clock: clock);
      await n2.load();
      expect(n2.items.length, 2);
      expect(n2.unread, 0);
      await sub.cancel();
    });
  });

  group('FlightStatusService', () {
    late NotificationStore n;
    late FlightStatusService s;

    setUp(() async {
      n = NotificationStore(clock: clock, random: Random(1));
      await n.load();
      s = FlightStatusService(notifications: n, clock: clock, random: Random(3), eventProbability: 0);
    });

    tearDown(() => s.dispose());

    test('trackingFor creates once and returns the same entry', () {
      final t = s.trackingFor('6E 2175', dep, arr);
      expect(t.status, FlightStatus.scheduled);
      expect(t.delayMinutes, 0);
      expect(t.gate, isNotEmpty);
      expect(s.trackingFor('6E 2175', dep, arr).gate, t.gate);
      expect(s.tracked.length, 1);
    });

    test('simulateDelay updates tracking and pushes a delay notification', () {
      s.trackingFor('6E 2175', dep, arr);
      expect(s.simulateDelay('6E 2175', 30), isTrue);
      final t = s.tracking('6E 2175')!;
      expect(t.delayMinutes, 30);
      expect(t.status, FlightStatus.delayed);
      expect(t.estimatedDeparture, dep.add(const Duration(minutes: 30)));
      expect(t.estimatedArrival, arr.add(const Duration(minutes: 30)));
      expect(n.items.first.kind, NotificationKind.delay);
      expect(n.items.first.body, contains('6E 2175'));
      expect(s.eventsFor('6E 2175').map((e) => e.kind), contains('delay'));
    });

    test('simulateGateChange updates the gate and pushes a gate notification', () {
      s.trackingFor('6E 2175', dep, arr);
      expect(s.simulateGateChange('6E 2175', '22B'), isTrue);
      expect(s.tracking('6E 2175')!.gate, '22B');
      expect(n.items.first.kind, NotificationKind.gate);
      expect(n.items.first.body, contains('22B'));
    });

    test('hooks on an untracked flight do nothing', () {
      expect(s.simulateDelay('6E 9999', 15), isFalse);
      expect(n.items, isEmpty);
    });

    test('tick advances the status with the clock', () {
      s.trackingFor('6E 2175', dep, arr);
      now = dep.subtract(const Duration(minutes: 30));
      s.tick();
      expect(s.tracking('6E 2175')!.status, FlightStatus.boarding);
      expect(n.items.first.kind, NotificationKind.boarding);
      now = dep.add(const Duration(minutes: 5));
      s.tick();
      expect(s.tracking('6E 2175')!.status, FlightStatus.departed);
      now = dep.add(const Duration(hours: 1));
      s.tick();
      final mid = s.tracking('6E 2175')!;
      expect(mid.status, FlightStatus.enRoute);
      expect(mid.progress, closeTo(0.5, 0.01));
      now = arr.add(const Duration(minutes: 1));
      s.tick();
      expect(s.tracking('6E 2175')!.status, FlightStatus.landed);
      expect(s.tracking('6E 2175')!.progress, 1.0);
    });

    test('random events can add delays when probability is 1', () {
      final r = FlightStatusService(notifications: n, clock: clock, random: Random(5), eventProbability: 1);
      r.trackingFor('6E 2175', dep, arr);
      r.tick();
      final t = r.tracking('6E 2175')!;
      expect(t.delayMinutes > 0 || t.gate != r.trackingFor('6E 2175', dep, arr).gate || n.items.isNotEmpty,
          isTrue);
      expect(n.items.map((e) => e.kind), anyOf(contains('delay'), contains('gate')));
      r.dispose();
    });

    test('start runs a periodic timer and dispose stops it', () async {
      final t = FlightStatusService(notifications: n, clock: clock, eventProbability: 0);
      expect(t.isRunning, isFalse, reason: 'no timer before start()');
      t.start(tick: const Duration(milliseconds: 10));
      expect(t.isRunning, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(t.tickCount, greaterThan(0));
      t.dispose();
      expect(t.isRunning, isFalse);
      final count = t.tickCount;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(t.tickCount, count);
    });
  });

  group('BaggageService', () {
    late NotificationStore n;
    setUp(() async {
      n = NotificationStore(clock: clock, random: Random(1));
      await n.load();
    });

    test('seeds the sample bag', () {
      final b = BaggageService(notifications: n, clock: clock);
      final bags = b.bagsFor('K7Q2ZP');
      expect(bags.single.rfidTag, '6E-RFID-0011523');
      expect(bags.single.scans, isEmpty);
      expect(b.isAutoScanning, isFalse);
      b.dispose();
    });

    test('scanNext walks all 6 stages in order and stops at collected', () {
      final b = BaggageService(notifications: n, clock: clock);
      const tag = '6E-RFID-0011523';
      for (final stage in BagScanStage.values) {
        now = now.add(const Duration(minutes: 10));
        final scan = b.scanNext(tag);
        expect(scan!.stage, stage);
        expect(scan.at, now);
        expect(scan.location, isNotEmpty);
      }
      final bag = b.bag(tag)!;
      expect(bag.scans.map((s) => s.stage), BagScanStage.values);
      expect(bag.isCollected, isTrue);
      expect(bag.scans.first.location, startsWith('DEL'));
      expect(bag.scans[4].location, startsWith('BOM'));
      expect(bag.scans.last.location, 'Collected');
      expect(b.scanNext(tag), isNull);
      expect(b.bag(tag)!.scans.length, 6);
      expect(n.items.where((e) => e.kind == NotificationKind.baggage).length, 6);
    });

    test('ensureBagsForBooking creates one bag per passenger when a check-in bag is included', () {
      final b = BaggageService(notifications: n, clock: clock, random: Random(2));
      final booking = Booking(
        pnr: 'ABC234',
        bookedAt: now,
        passengers: const [
          Passenger(id: 'a', firstName: 'A', lastName: 'One', age: 30),
          Passenger(id: 'b', firstName: 'B', lastName: 'Two', age: 30),
        ],
        segments: [
          BookedSegment(
            flight: Flight(id: 'f', baseFare: 4000, legs: [
              FlightLeg(flightNo: '6E 1', from: 'BLR', to: 'GOI', departure: dep, arrival: arr),
            ]),
            family: FareFamily.classic,
          ),
        ],
        addOns: const {},
        fare: FareBreakdown.zero,
      );
      final bags = b.ensureBagsForBooking(booking);
      expect(bags.length, 2);
      expect(bags.first.rfidTag, matches(RegExp(r'^6E-RFID-\d{7}$')));
      expect(bags.first.from, 'BLR');
      expect(b.ensureBagsForBooking(booking).length, 2, reason: 'idempotent');
      b.dispose();
    });

    test('auto-scan timer starts on demand and dispose stops it', () async {
      final b = BaggageService(notifications: n, clock: clock);
      b.startAutoScan(interval: const Duration(milliseconds: 10));
      expect(b.isAutoScanning, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(b.bag('6E-RFID-0011523')!.scans, isNotEmpty);
      b.dispose();
      expect(b.isAutoScanning, isFalse);
    });
  });

  group('ProfileStore', () {
    test('profile and saved travellers CRUD persist', () async {
      final p = ProfileStore(clock: clock, random: Random(1));
      await p.load();
      expect(p.me.lastName, isNotEmpty);
      p.setFrequentFlyerNo('FF-1234567');
      final t = p.addTraveller(const Passenger(id: '', firstName: 'Riya', lastName: 'Sen', age: 12));
      expect(t.id, isNotEmpty);
      p.updateTraveller(t.copyWith(age: 13));
      final count = p.savedTravellers.length;
      await p.flush();
      final p2 = ProfileStore(clock: clock);
      await p2.load();
      expect(p2.me.frequentFlyerNo, 'FF-1234567');
      expect(p2.frequentFlyerNo, 'FF-1234567');
      expect(p2.savedTravellers.length, count);
      expect(p2.savedTravellers.firstWhere((x) => x.id == t.id).age, 13);
      p2.removeTraveller(t.id);
      expect(p2.savedTravellers.any((x) => x.id == t.id), isFalse);
    });
  });
}
