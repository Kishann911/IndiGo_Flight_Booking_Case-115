import '../data/sample_data.dart';
import '../models/add_on.dart';
import '../models/booking.dart';
import '../models/fare_breakdown.dart';
import '../models/fare_family.dart';
import '../models/flight.dart';
import '../models/meal.dart';
import '../models/seat.dart';

/// All fare maths. Pure Dart; every amount is whole rupees.
class PricingEngine {
  PricingEngine._();

  /// Advance-purchase multiplier on the base fare.
  static double bookingWindowMultiplier(int daysBefore) {
    if (daysBefore >= 30) return 0.85;
    if (daysBefore >= 15) return 0.95;
    if (daysBefore >= 7) return 1.00;
    if (daysBefore >= 3) return 1.15;
    return 1.30;
  }

  /// Calendar days from [today]'s date to [departure]'s date (time of day ignored).
  static int daysBetween(DateTime today, DateTime departure) {
    final a = DateTime.utc(today.year, today.month, today.day);
    final b = DateTime.utc(departure.year, departure.month, departure.day);
    return b.difference(a).inDays;
  }

  /// Lite fare per passenger after the booking-window multiplier.
  static int dynamicBaseFare(Flight f, DateTime today) =>
      (f.baseFare * bookingWindowMultiplier(daysBetween(today, f.departure))).round();

  static int familyCharge(FareFamily family) => FareFamilyInfo.of(family).charge;

  /// Tier price; Flex gets standard / standard-middle seats free.
  static int seatFee(Seat s, FareFamily fam) {
    if (fam == FareFamily.flex && s.tier.isStandard) return 0;
    return s.tier.price;
  }

  static int mealCharge(Meal m, FareFamily fam, bool firstMealForPassengerOnSegment) {
    if (fam != FareFamily.lite && firstMealForPassengerOnSegment) return 0;
    return m.price;
  }

  /// Baggage is flat per booking; priority and lounge are per passenger.
  static int addOnCharge(AddOnType t, int passengers) =>
      t.perPassenger ? t.price * passengers : t.price;

  /// 5% of (base + family) plus ₹450 per segment per passenger.
  static int taxes(int fareSubtotal, int segments, int passengers) =>
      (0.05 * fareSubtotal).round() + 450 * segments * passengers;

  /// Full price for a set of booked segments. Each passenger has at most one
  /// meal per segment, so every meal counts as that passenger's first meal.
  /// Unknown seat or meal ids are ignored.
  static FareBreakdown quote({
    required List<BookedSegment> segments,
    required int passengers,
    required Set<AddOnType> addOns,
    required DateTime today,
    required Map<String, Meal> mealsById,
    required Map<String, Seat> seatsById,
  }) {
    var base = 0, family = 0, seats = 0, meals = 0, extras = 0;
    for (final seg in segments) {
      base += dynamicBaseFare(seg.flight, today) * passengers;
      family += familyCharge(seg.family) * passengers;
      for (final seatId in seg.seats.values) {
        final seat = seatsById[seatId];
        if (seat != null) seats += seatFee(seat, seg.family);
      }
      for (final mealId in seg.meals.values) {
        final meal = mealsById[mealId];
        if (meal != null) meals += mealCharge(meal, seg.family, true);
      }
    }
    for (final a in addOns) {
      extras += addOnCharge(a, passengers);
    }
    final tax = taxes(base + family, segments.length, passengers);
    return FareBreakdown(
      baseFare: base,
      familyCharges: family,
      seatFees: seats,
      mealCharges: meals,
      addOnCharges: extras,
      taxesAndFees: tax,
      total: base + family + seats + meals + extras + tax,
    );
  }

  /// Refund if [b] is cancelled at [now].
  /// - All-Flex booking: the full total if now ≤ first departure − 2 h, else 0.
  /// - Otherwise: max(0, total − Σ cancellation fee per segment − add-on charges)
  ///   (Lite ₹3,999, Classic ₹2,999, Flex segments in a mixed booking ₹0).
  /// - An already-cancelled booking refunds 0.
  static int cancellationRefund(Booking b, DateTime now) {
    if (b.isCancelled || b.segments.isEmpty) return 0;
    final allFlex = b.segments.every((s) => s.family == FareFamily.flex);
    if (allFlex) {
      final cutoff = b.departure.subtract(FareFamilyInfo.flex.freeCancellationCutoff!);
      return now.isAfter(cutoff) ? 0 : b.fare.total;
    }
    final fees = b.segments.fold<int>(0, (sum, s) => sum + FareFamilyInfo.of(s.family).cancellationFee);
    final refund = b.fare.total - fees - b.fare.addOnCharges;
    return refund < 0 ? 0 : refund;
  }

  /// Lowest Lite dynamic fare among [day]'s flights (powers the fare calendar).
  static int lowestFareForDay(String from, String to, DateTime day, DateTime today) {
    final flights = SampleData.flightsFor(from, to, day);
    var best = -1;
    for (final f in flights) {
      final fare = dynamicBaseFare(f, today);
      if (best < 0 || fare < best) best = fare;
    }
    return best < 0 ? 0 : best;
  }
}
