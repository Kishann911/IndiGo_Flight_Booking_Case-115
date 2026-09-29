import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/data/sample_data.dart';
import 'package:indigo_flight_booking/logic/checkin_rules.dart';
import 'package:indigo_flight_booking/models/models.dart';

void main() {
  final start = DateTime(2026, 10, 1);

  test('10 airports', () {
    expect(SampleData.airports.map((a) => a.code).toSet(),
        {'DEL', 'BOM', 'BLR', 'HYD', 'MAA', 'CCU', 'GOI', 'PNQ', 'AMD', 'COK'});
  });

  test('flightsFor invariants over all pairs and 10 days', () {
    final codes = SampleData.airports.map((a) => a.code).toList();
    for (final from in codes) {
      for (final to in codes) {
        if (from == to) continue;
        for (var d = 0; d < 10; d++) {
          final day = start.add(Duration(days: d));
          final flights = SampleData.flightsFor(from, to, day);
          expect(flights.length, inInclusiveRange(4, 7));
          expect(flights.where((f) => f.stops == 0).length, greaterThanOrEqualTo(3));
          final oneStop = flights.where((f) => f.stops == 1).toList();
          expect(oneStop.length, inInclusiveRange(1, 2));
          for (final f in flights) {
            expect(f.from, from);
            expect(f.to, to);
            expect(f.departure.day, day.day);
            expect(f.baseFare, inInclusiveRange(2500, 7800));
            for (final l in f.legs) {
              expect(l.flightNo, matches(RegExp(r'^6E \d{3,4}$')));
              expect(l.duration.inMinutes, greaterThan(0));
            }
          }
          for (final f in oneStop) {
            expect(SampleData.hubs, contains(f.legs.first.to));
            expect(f.layovers.single.inMinutes, inInclusiveRange(55, 180));
          }
          for (var i = 1; i < flights.length; i++) {
            expect(flights[i].departure.isBefore(flights[i - 1].departure), isFalse);
          }
        }
      }
    }
  });

  test('flightsFor is deterministic and ignores time of day', () {
    final a = SampleData.flightsFor('DEL', 'BOM', DateTime(2026, 10, 5, 1));
    final b = SampleData.flightsFor('DEL', 'BOM', DateTime(2026, 10, 5, 23));
    expect(a.map((f) => f.id), b.map((f) => f.id));
    expect(a.map((f) => f.baseFare), b.map((f) => f.baseFare));
    expect(SampleData.flightsFor('DEL', 'DEL', start), isEmpty);
  });

  test('occupied seats are deterministic and about 40%', () {
    final a = SampleData.occupiedSeats('6E 2175', start);
    expect(SampleData.occupiedSeats('6E 2175', start), a);
    expect(a.length, inInclusiveRange(50, 95));
  });

  test('at least 10 meals covering every cuisine', () {
    expect(SampleData.meals.length, greaterThanOrEqualTo(10));
    expect(SampleData.meals.map((m) => m.cuisine).toSet(), Meal.cuisines.toSet());
    for (final m in SampleData.meals) {
      expect(Meal.dietaryTags.toSet().containsAll(m.dietary), isTrue);
    }
  });

  test('sample booking departs ~20 h out with check-in open', () {
    final now = DateTime(2026, 10, 1, 9, 7);
    final b = SampleData.sampleBooking(now);
    expect(b.pnr, 'K7Q2ZP');
    expect(b.departure.difference(now).inHours, inInclusiveRange(19, 20));
    expect(CheckInRules.isOpen(b.departure, now), isTrue);
    expect(b.fare.total, greaterThan(0));
    expect(SampleData.sampleBags().single.rfidTag, '6E-RFID-0011523');
  });
}
