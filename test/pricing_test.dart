import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/data/sample_data.dart';
import 'package:indigo_flight_booking/logic/formatters.dart';
import 'package:indigo_flight_booking/logic/pricing.dart';
import 'package:indigo_flight_booking/models/models.dart';

final today = DateTime(2026, 10, 1, 9, 0);

Flight flightOn(DateTime dep, {int baseFare = 5000, String no = '6E 2001'}) => Flight(
      id: 'T-$no-${dep.toIso8601String()}',
      baseFare: baseFare,
      legs: [
        FlightLeg(
          flightNo: no,
          from: 'DEL',
          to: 'BOM',
          departure: dep,
          arrival: dep.add(const Duration(hours: 2, minutes: 10)),
        ),
      ],
    );

Booking bookingWith(List<BookedSegment> segs, {int total = 20000, int addOns = 0}) => Booking(
      pnr: 'ABC234',
      bookedAt: today,
      passengers: const [Passenger(id: 'p1', firstName: 'Asha', lastName: 'Rao', age: 30)],
      segments: segs,
      addOns: const {},
      fare: FareBreakdown(
        baseFare: 0,
        familyCharges: 0,
        seatFees: 0,
        mealCharges: 0,
        addOnCharges: addOns,
        taxesAndFees: 0,
        total: total,
      ),
    );

void main() {
  group('bookingWindowMultiplier boundaries', () {
    const expected = {
      0: 1.30,
      2: 1.30,
      3: 1.15,
      6: 1.15,
      7: 1.00,
      14: 1.00,
      15: 0.95,
      29: 0.95,
      30: 0.85,
      90: 0.85,
    };
    expected.forEach((days, m) {
      test('$days days → $m', () {
        expect(PricingEngine.bookingWindowMultiplier(days), m);
      });
    });

    test('negative days are treated as last-minute', () {
      expect(PricingEngine.bookingWindowMultiplier(-1), 1.30);
    });
  });

  group('dynamicBaseFare', () {
    test('uses calendar days between today and departure', () {
      final f = flightOn(DateTime(2026, 10, 31, 6, 0)); // 30 days
      expect(PricingEngine.daysBetween(today, f.departure), 30);
      expect(PricingEngine.dynamicBaseFare(f, today), 4250);
    });

    test('rounds the multiplied fare', () {
      final f = flightOn(DateTime(2026, 10, 4, 23, 0), baseFare: 3333); // 3 days, 1.15
      expect(PricingEngine.dynamicBaseFare(f, today), 3833); // 3832.95
    });

    test('same day is 1.30', () {
      final f = flightOn(DateTime(2026, 10, 1, 22, 0));
      expect(PricingEngine.dynamicBaseFare(f, today), 6500);
    });
  });

  group('seat tiers and fees', () {
    Seat s(String id) => Seat.tryParse(id)!;

    test('tiers by row and letter', () {
      expect(s('1A').tier, SeatTier.xl);
      expect(s('1B').tier, SeatTier.xl);
      expect(s('2B').tier, SeatTier.front);
      expect(s('5C').tier, SeatTier.front);
      expect(s('6A').tier, SeatTier.standard);
      expect(s('6B').tier, SeatTier.standardMiddle);
      expect(s('6C').tier, SeatTier.standard);
      expect(s('12A').tier, SeatTier.xl);
      expect(s('13C').tier, SeatTier.xl);
      expect(s('14A').tier, SeatTier.standard);
      expect(s('14B').tier, SeatTier.standardMiddle);
      expect(s('14C').tier, SeatTier.standard);
    });

    test('fees for Lite and Classic', () {
      for (final fam in [FareFamily.lite, FareFamily.classic]) {
        expect(PricingEngine.seatFee(s('1A'), fam), 799);
        expect(PricingEngine.seatFee(s('2A'), fam), 449);
        expect(PricingEngine.seatFee(s('5B'), fam), 449);
        expect(PricingEngine.seatFee(s('6A'), fam), 299);
        expect(PricingEngine.seatFee(s('6B'), fam), 199);
        expect(PricingEngine.seatFee(s('6C'), fam), 299);
        expect(PricingEngine.seatFee(s('12C'), fam), 799);
        expect(PricingEngine.seatFee(s('13B'), fam), 799);
        expect(PricingEngine.seatFee(s('14B'), fam), 199);
      }
    });

    test('Flex gets standard seats free but pays for xl and front', () {
      expect(PricingEngine.seatFee(s('6A'), FareFamily.flex), 0);
      expect(PricingEngine.seatFee(s('14B'), FareFamily.flex), 0);
      expect(PricingEngine.seatFee(s('1A'), FareFamily.flex), 799);
      expect(PricingEngine.seatFee(s('12A'), FareFamily.flex), 799);
      expect(PricingEngine.seatFee(s('2C'), FareFamily.flex), 449);
    });

    test('cabin has 180 seats in 30 rows', () {
      final seats = CabinLayout.build();
      expect(seats.length, 180);
      expect(seats.first.id, '1A');
      expect(seats.last.id, '30F');
      expect(Seat.tryParse('31A'), isNull);
      expect(Seat.tryParse('7G'), isNull);
    });
  });

  test('family charges', () {
    expect(PricingEngine.familyCharge(FareFamily.lite), 0);
    expect(PricingEngine.familyCharge(FareFamily.classic), 800);
    expect(PricingEngine.familyCharge(FareFamily.flex), 2200);
  });

  group('meals', () {
    const meal = Meal(id: 'm', name: 'Paneer', cuisine: 'North Indian', dietary: {'veg'}, price: 400);
    test('Lite always pays', () {
      expect(PricingEngine.mealCharge(meal, FareFamily.lite, true), 400);
    });
    test('Classic/Flex first meal is free, later meals paid', () {
      expect(PricingEngine.mealCharge(meal, FareFamily.classic, true), 0);
      expect(PricingEngine.mealCharge(meal, FareFamily.flex, true), 0);
      expect(PricingEngine.mealCharge(meal, FareFamily.classic, false), 400);
    });
  });

  group('add-ons', () {
    test('priority boarding is 299 per passenger', () {
      expect(PricingEngine.addOnCharge(AddOnType.priorityBoarding, 1), 299);
      expect(PricingEngine.addOnCharge(AddOnType.priorityBoarding, 3), 897);
    });
    test('lounge is 1500 per passenger', () {
      expect(PricingEngine.addOnCharge(AddOnType.loungeAccess, 2), 3000);
    });
    test('baggage is flat per booking', () {
      expect(PricingEngine.addOnCharge(AddOnType.extraBaggage5kg, 4), 1800);
      expect(PricingEngine.addOnCharge(AddOnType.extraBaggage10kg, 4), 3400);
    });
  });

  test('taxes = 5% of base+family + 450 per segment per passenger', () {
    expect(PricingEngine.taxes(11600, 1, 2), 580 + 900);
    expect(PricingEngine.taxes(10001, 2, 1), 500 + 900); // 500.05 rounds to 500
  });

  group('quote', () {
    test('known case: 2 pax, Classic, 12A + 14B, free meals, priority', () {
      final f = flightOn(DateTime(2026, 10, 11, 7, 0)); // 10 days → 1.00
      final meals = {for (final m in SampleData.meals) m.id: m};
      final mealId = SampleData.meals.first.id;
      final q = PricingEngine.quote(
        segments: [
          BookedSegment(
            flight: f,
            family: FareFamily.classic,
            seats: const {'p1': '12A', 'p2': '14B'},
            meals: {'p1': mealId, 'p2': mealId},
          ),
        ],
        passengers: 2,
        addOns: const {AddOnType.priorityBoarding},
        today: today,
        mealsById: meals,
        seatsById: CabinLayout.seatsById,
      );
      expect(
        q,
        const FareBreakdown(
          baseFare: 10000,
          familyCharges: 1600,
          seatFees: 998,
          mealCharges: 0,
          addOnCharges: 598,
          taxesAndFees: 1480,
          total: 14676,
        ),
      );
    });

    test('Lite pays for meals; two segments', () {
      final f1 = flightOn(DateTime(2026, 11, 5, 7, 0), baseFare: 4000); // 35 d → 0.85 → 3400
      final f2 = flightOn(DateTime(2026, 11, 9, 7, 0), baseFare: 4000, no: '6E 2002'); // 3400
      const meal = Meal(id: 'x', name: 'X', cuisine: 'Snacks', dietary: {'veg'}, price: 350);
      final q = PricingEngine.quote(
        segments: [
          BookedSegment(flight: f1, family: FareFamily.lite, meals: const {'p1': 'x'}),
          BookedSegment(flight: f2, family: FareFamily.lite),
        ],
        passengers: 1,
        addOns: const {},
        today: today,
        mealsById: const {'x': meal},
        seatsById: CabinLayout.seatsById,
      );
      expect(q.baseFare, 6800);
      expect(q.familyCharges, 0);
      expect(q.mealCharges, 350);
      expect(q.taxesAndFees, 340 + 900);
      expect(q.total, 6800 + 350 + 1240);
    });
  });

  group('cancellationRefund', () {
    final dep = DateTime(2026, 10, 20, 10, 0);

    test('Lite: total − 3999 per segment − add-ons', () {
      final b = bookingWith([BookedSegment(flight: flightOn(dep), family: FareFamily.lite)],
          total: 9000, addOns: 299);
      expect(PricingEngine.cancellationRefund(b, today), 9000 - 3999 - 299);
    });

    test('Classic: total − 2999 × segments − add-ons', () {
      final b = bookingWith([
        BookedSegment(flight: flightOn(dep), family: FareFamily.classic),
        BookedSegment(flight: flightOn(dep.add(const Duration(days: 3))), family: FareFamily.classic),
      ], total: 15000, addOns: 1800);
      expect(PricingEngine.cancellationRefund(b, today), 15000 - 5998 - 1800);
    });

    test('never negative', () {
      final b = bookingWith([BookedSegment(flight: flightOn(dep), family: FareFamily.lite)],
          total: 3000);
      expect(PricingEngine.cancellationRefund(b, today), 0);
    });

    test('Flex: full refund exactly 2 h before departure', () {
      final b = bookingWith([BookedSegment(flight: flightOn(dep), family: FareFamily.flex)],
          total: 12000, addOns: 500);
      expect(PricingEngine.cancellationRefund(b, dep.subtract(const Duration(hours: 2))), 12000);
    });

    test('Flex: nothing inside 2 h (2 h − 1 min before)', () {
      final b = bookingWith([BookedSegment(flight: flightOn(dep), family: FareFamily.flex)],
          total: 12000);
      final now = dep.subtract(const Duration(hours: 1, minutes: 59));
      expect(PricingEngine.cancellationRefund(b, now), 0);
    });

    test('an already-cancelled booking refunds nothing', () {
      final b = bookingWith([BookedSegment(flight: flightOn(dep), family: FareFamily.classic)])
          .copyWith(status: BookingStatus.cancelled);
      expect(PricingEngine.cancellationRefund(b, today), 0);
    });
  });

  group('lowestFareForDay', () {
    test('is the minimum Lite dynamic fare of that day', () {
      final day = DateTime(2026, 10, 12);
      final flights = SampleData.flightsFor('DEL', 'BOM', day);
      final min = flights
          .map((f) => PricingEngine.dynamicBaseFare(f, today))
          .reduce((a, b) => a < b ? a : b);
      expect(PricingEngine.lowestFareForDay('DEL', 'BOM', day, today), min);
    });

    test('advance days are cheaper on average than last-minute', () {
      int avg(int offset) {
        var sum = 0;
        for (var i = 0; i < 5; i++) {
          sum += PricingEngine.lowestFareForDay(
              'DEL', 'BLR', today.add(Duration(days: offset + i)), today);
        }
        return sum ~/ 5;
      }

      expect(avg(40), lessThan(avg(0)));
    });
  });

  group('Fmt.inr uses Indian digit grouping', () {
    test('examples', () {
      expect(Fmt.inr(0), '₹0');
      expect(Fmt.inr(999), '₹999');
      expect(Fmt.inr(12450), '₹12,450');
      expect(Fmt.inr(100000), '₹1,00,000');
      expect(Fmt.inr(12345678), '₹1,23,45,678');
      expect(Fmt.inr(-2999), '-₹2,999');
    });
    test('duration', () {
      expect(Fmt.duration(const Duration(hours: 2, minutes: 5)), '2h 5m');
      expect(Fmt.duration(const Duration(minutes: 55)), '55m');
      expect(Fmt.duration(const Duration(hours: 3)), '3h');
    });
  });
}
