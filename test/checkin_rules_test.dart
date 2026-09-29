import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/logic/checkin_rules.dart';
import 'package:indigo_flight_booking/models/models.dart';

void main() {
  final dep = DateTime(2026, 10, 10, 12, 0);
  Duration h(int hours, [int minutes = 0]) => Duration(hours: hours, minutes: minutes);

  group('isOpen', () {
    test('opens exactly 48 h before', () {
      expect(CheckInRules.isOpen(dep, dep.subtract(h(48))), isTrue);
    });
    test('closed just before the 48 h mark', () {
      expect(CheckInRules.isOpen(dep, dep.subtract(h(48, 1))), isFalse);
    });
    test('open just inside 48 h', () {
      expect(CheckInRules.isOpen(dep, dep.subtract(h(47, 59))), isTrue);
    });
    test('open 61 min before', () {
      expect(CheckInRules.isOpen(dep, dep.subtract(h(1, 1))), isTrue);
    });
    test('closes at 60 min before', () {
      expect(CheckInRules.isOpen(dep, dep.subtract(h(1))), isFalse);
    });
    test('closed 59 min before and after departure', () {
      expect(CheckInRules.isOpen(dep, dep.subtract(h(0, 59))), isFalse);
      expect(CheckInRules.isOpen(dep, dep.add(h(1))), isFalse);
    });
  });

  group('windowLabel', () {
    test('days and hours until opening', () {
      expect(CheckInRules.windowLabel(dep, dep.subtract(h(48 + 76))), 'Opens in 3 d 4 h');
    });
    test('hours and minutes until opening when under a day', () {
      expect(CheckInRules.windowLabel(dep, dep.subtract(h(53, 10))), 'Opens in 5 h 10 m');
    });
    test('open with time to close', () {
      expect(CheckInRules.windowLabel(dep, dep.subtract(h(6, 10))), 'Open — closes in 5 h 10 m');
    });
    test('open with more than a day left', () {
      expect(CheckInRules.windowLabel(dep, dep.subtract(h(47))), 'Open — closes in 1 d 22 h');
    });
    test('closed', () {
      expect(CheckInRules.windowLabel(dep, dep.subtract(h(0, 30))), 'Closed');
    });
  });

  test('boarding time is 45 min before departure', () {
    expect(CheckInRules.boardingTime(dep), DateTime(2026, 10, 10, 11, 15));
  });

  group('boardingZone', () {
    test('priority is always zone 1', () {
      expect(CheckInRules.boardingZone(true, '28F'), 1);
    });
    test('rows 1–5 zone 1', () {
      expect(CheckInRules.boardingZone(false, '1A'), 1);
      expect(CheckInRules.boardingZone(false, '5F'), 1);
    });
    test('rows 6–17 zone 2', () {
      expect(CheckInRules.boardingZone(false, '6A'), 2);
      expect(CheckInRules.boardingZone(false, '17C'), 2);
    });
    test('rows 18+ zone 3', () {
      expect(CheckInRules.boardingZone(false, '18A'), 3);
      expect(CheckInRules.boardingZone(false, '30F'), 3);
    });
  });

  test('BCBP-like QR payload', () {
    final leg = FlightLeg(
      flightNo: '6E 2175',
      from: 'DEL',
      to: 'BOM',
      departure: DateTime(2026, 9, 30, 6, 0), // day 273
      arrival: DateTime(2026, 9, 30, 8, 10),
    );
    const p = Passenger(id: 'p1', firstName: 'Kishan', lastName: 'Ojha', age: 24);
    expect(
      CheckInRules.bcbpPayload(passenger: p, pnr: 'K7Q2ZP', leg: leg, seatId: '14C', sequence: 1),
      'M1OJHA/KISHAN EK7Q2ZP DELBOM6E 2175 273 Y 014C 0001',
    );
  });
}
