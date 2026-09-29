import 'package:flutter_test/flutter_test.dart';
import 'package:indigo_flight_booking/data/sample_data.dart';
import 'package:indigo_flight_booking/logic/pricing.dart';
import 'package:indigo_flight_booking/models/models.dart';

/// The worked example printed in docs/PRICING_AND_RULES.md, computed by the
/// real PricingEngine: 2 passengers, one Classic segment, booked 19 days ahead.
void main() {
  final today = DateTime(2026, 10, 1, 9);
  final dep = DateTime(2026, 10, 20, 8, 30);
  final flight = Flight(
    id: 'worked-example',
    baseFare: 5000,
    legs: [
      FlightLeg(
        flightNo: '6E 2134',
        from: 'DEL',
        to: 'BOM',
        departure: dep,
        arrival: dep.add(const Duration(hours: 2, minutes: 10)),
      ),
    ],
  );
  final segment = BookedSegment(
    flight: flight,
    family: FareFamily.classic,
    seats: const {'p1': '12A', 'p2': '14C'},
    meals: const {'p1': 'm01', 'p2': 'm04'},
  );
  final addOns = {AddOnType.priorityBoarding, AddOnType.extraBaggage5kg};

  FareBreakdown quote() => PricingEngine.quote(
        segments: [segment],
        passengers: 2,
        addOns: addOns,
        today: today,
        mealsById: SampleData.mealsById,
        seatsById: CabinLayout.seatsById,
      );

  test('booking window: 19 days ahead -> x0.95 -> Rs 4,750 per passenger', () {
    expect(PricingEngine.daysBetween(today, dep), 19);
    expect(PricingEngine.bookingWindowMultiplier(19), 0.95);
    expect(PricingEngine.dynamicBaseFare(flight, today), 4750);
  });

  test('worked example line by line', () {
    final q = quote();
    expect(q.baseFare, 9500); // 4,750 x 2
    expect(q.familyCharges, 1600); // Classic +800 x 2
    expect(q.seatFees, 1098); // 12A xl 799 + 14C standard 299
    expect(q.mealCharges, 0); // first meal free on Classic
    expect(q.addOnCharges, 2398); // 299 x 2 + 1,800
    expect(PricingEngine.taxes(9500 + 1600, 1, 2), 1455); // round(5% x 11,100)=555 + 450 x 2
    expect(q.taxesAndFees, 1455);
    expect(q.total, 16051);
  });

  test('worked example cancellation refund (Classic)', () {
    final booking = Booking(
      pnr: 'ABCDE2',
      bookedAt: today,
      passengers: const [
        Passenger(id: 'p1', firstName: 'Asha', lastName: 'Rao', age: 31),
        Passenger(id: 'p2', firstName: 'Bina', lastName: 'Rao', age: 29),
      ],
      segments: [segment],
      addOns: addOns,
      fare: quote(),
    );
    // 16,051 - 2,999 cancellation fee - 2,398 add-ons = 10,654
    expect(PricingEngine.cancellationRefund(booking, today), 10654);
  });
}
