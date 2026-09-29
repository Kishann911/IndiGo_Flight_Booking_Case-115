import 'dart:math';

import '../logic/pricing.dart';
import '../models/models.dart';

/// Deterministic demo data. Nothing here reads `DateTime.now()`: every value
/// derives from its arguments via a stable string hash.
class SampleData {
  SampleData._();

  static const airports = <Airport>[
    Airport(code: 'DEL', city: 'Delhi', name: 'Indira Gandhi International'),
    Airport(code: 'BOM', city: 'Mumbai', name: 'Chhatrapati Shivaji Maharaj International'),
    Airport(code: 'BLR', city: 'Bengaluru', name: 'Kempegowda International'),
    Airport(code: 'HYD', city: 'Hyderabad', name: 'Rajiv Gandhi International'),
    Airport(code: 'MAA', city: 'Chennai', name: 'Chennai International'),
    Airport(code: 'CCU', city: 'Kolkata', name: 'Netaji Subhas Chandra Bose International'),
    Airport(code: 'GOI', city: 'Goa', name: 'Dabolim'),
    Airport(code: 'PNQ', city: 'Pune', name: 'Pune International'),
    Airport(code: 'AMD', city: 'Ahmedabad', name: 'Sardar Vallabhbhai Patel International'),
    Airport(code: 'COK', city: 'Kochi', name: 'Cochin International'),
  ];

  static const hubs = ['DEL', 'BOM', 'BLR', 'HYD'];

  static Airport? airport(String code) {
    for (final a in airports) {
      if (a.code == code) return a;
    }
    return null;
  }

  /// City name for a code, or the code itself if unknown.
  static String cityOf(String code) => airport(code)?.city ?? code;

  static const Map<String, (double, double)> _coords = {
    'DEL': (28.556, 77.100),
    'BOM': (19.089, 72.868),
    'BLR': (13.199, 77.706),
    'HYD': (17.240, 78.429),
    'MAA': (12.994, 80.171),
    'CCU': (22.654, 88.447),
    'GOI': (15.381, 73.831),
    'PNQ': (18.582, 73.920),
    'AMD': (23.077, 72.635),
    'COK': (10.152, 76.402),
  };

  /// Great-circle distance in km (the route distance table).
  static int distanceKm(String a, String b) {
    final p = _coords[a], q = _coords[b];
    if (p == null || q == null || a == b) return 0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(q.$1 - p.$1), dLon = rad(q.$2 - p.$2);
    final h = pow(sin(dLat / 2), 2) + cos(rad(p.$1)) * cos(rad(q.$1)) * pow(sin(dLon / 2), 2);
    return (6371 * 2 * asin(sqrt(h))).round();
  }

  /// Route base fare (Lite, before the booking-window multiplier), ₹2,800–₹7,500.
  static int routeFare(String from, String to) =>
      _round10((2800 + distanceKm(from, to) * 2.4).clamp(2800, 7500).toDouble());

  /// Block time: 30 min taxi + cruise at ~780 km/h, rounded to 5 min.
  static Duration blockTime(String from, String to) {
    final mins = 30 + distanceKm(from, to) / 780 * 60;
    return Duration(minutes: (mins / 5).round() * 5);
  }

  static int _round10(double v) => (v / 10).round() * 10;

  /// Stable 31-bit string hash (identical on VM and web).
  static int stableHash(String s) {
    var h = 7;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) % 2147483647;
    }
    return h;
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// 4–7 flights for [date] (time of day ignored), sorted by departure:
  /// 3–5 non-stop plus 1–2 one-stop via a hub with a 55–180 min layover.
  static List<Flight> flightsFor(String from, String to, DateTime date) {
    if (from == to || !_coords.containsKey(from) || !_coords.containsKey(to)) return const [];
    final rng = Random(stableHash('$from>$to@${_dayKey(date)}'));
    final day = DateTime(date.year, date.month, date.day);
    final usedNos = <String>{};
    String nextNo() {
      while (true) {
        final no = '6E ${100 + rng.nextInt(6900)}';
        if (usedNos.add(no)) return no;
      }
    }

    final ymd = '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
    Flight make(List<FlightLeg> legs, int fare) => Flight(
          id: '${legs.map((l) => l.flightNo.replaceAll(' ', '')).join('-')}_${ymd}_$from$to',
          legs: legs,
          baseFare: fare,
        );

    final routeBase = routeFare(from, to);
    final flights = <Flight>[];

    // Non-stop: distinct departure slots between 05:00 and 22:00 (5-min steps).
    final directCount = 3 + rng.nextInt(3);
    final slots = <int>{};
    while (slots.length < directCount) {
      slots.add(300 + rng.nextInt(205) * 5);
    }
    for (final slot in slots) {
      final dep = day.add(Duration(minutes: slot));
      final fare = _round10(routeBase * (0.92 + 0.16 * rng.nextDouble())).clamp(2800, 7800);
      flights.add(make([
        FlightLeg(flightNo: nextNo(), from: from, to: to, departure: dep, arrival: dep.add(blockTime(from, to))),
      ], fare));
    }

    // One-stop via a hub that is not an endpoint.
    final viaOptions = hubs.where((h) => h != from && h != to).toList();
    final connCount = 1 + rng.nextInt(2);
    for (var i = 0; i < connCount; i++) {
      final hub = viaOptions[rng.nextInt(viaOptions.length)];
      final dep1 = day.add(Duration(minutes: 300 + rng.nextInt(157) * 5)); // 05:00–18:00
      final arr1 = dep1.add(blockTime(from, hub));
      final layover = Duration(minutes: 55 + rng.nextInt(26) * 5); // 55–180
      final dep2 = arr1.add(layover);
      final arr2 = dep2.add(blockTime(hub, to));
      final fare = max(2800, _round10(routeBase * (0.86 + 0.1 * rng.nextDouble())));
      flights.add(make([
        FlightLeg(flightNo: nextNo(), from: from, to: hub, departure: dep1, arrival: arr1),
        FlightLeg(flightNo: nextNo(), from: hub, to: to, departure: dep2, arrival: arr2),
      ], fare));
    }

    flights.sort((a, b) => a.departure.compareTo(b.departure));
    return flights;
  }

  static const meals = <Meal>[
    Meal(id: 'm01', name: 'Paneer Butter Masala with Jeera Rice', cuisine: 'North Indian', dietary: {'veg', 'gluten-free'}, price: 450),
    Meal(id: 'm02', name: 'Chicken Dum Biryani', cuisine: 'North Indian', dietary: {'non-veg'}, price: 500),
    Meal(id: 'm03', name: 'Rajma Chawal', cuisine: 'North Indian', dietary: {'veg', 'vegan', 'gluten-free'}, price: 380),
    Meal(id: 'm04', name: 'Masala Dosa with Chutney', cuisine: 'South Indian', dietary: {'veg'}, price: 350),
    Meal(id: 'm05', name: 'Idli Sambar', cuisine: 'South Indian', dietary: {'veg', 'vegan', 'gluten-free', 'diabetic'}, price: 300),
    Meal(id: 'm06', name: 'Jain Rava Upma', cuisine: 'South Indian', dietary: {'veg', 'jain', 'vegan'}, price: 320),
    Meal(id: 'm07', name: 'Grilled Chicken Sandwich', cuisine: 'Continental', dietary: {'non-veg'}, price: 420),
    Meal(id: 'm08', name: 'Penne Arrabbiata', cuisine: 'Continental', dietary: {'veg', 'vegan'}, price: 400),
    Meal(id: 'm09', name: 'Quinoa Salad Bowl', cuisine: 'Continental', dietary: {'veg', 'vegan', 'gluten-free', 'diabetic'}, price: 450),
    Meal(id: 'm10', name: 'Veg Hakka Noodles', cuisine: 'Asian', dietary: {'veg', 'vegan'}, price: 380),
    Meal(id: 'm11', name: 'Chicken Teriyaki Rice Bowl', cuisine: 'Asian', dietary: {'non-veg'}, price: 480),
    Meal(id: 'm12', name: 'Jain Poha', cuisine: 'Snacks', dietary: {'veg', 'jain', 'vegan', 'gluten-free'}, price: 250),
    Meal(id: 'm13', name: 'Roasted Makhana & Nuts', cuisine: 'Snacks', dietary: {'veg', 'jain', 'vegan', 'gluten-free', 'diabetic'}, price: 220),
    Meal(id: 'm14', name: 'Egg Mayo Sandwich', cuisine: 'Snacks', dietary: {'non-veg'}, price: 280),
  ];

  static final Map<String, Meal> mealsById = {for (final m in meals) m.id: m};

  /// Deterministic ~40% of the 180 seats, per flight number and date.
  static Set<String> occupiedSeats(String flightNo, DateTime date) {
    final rng = Random(stableHash('seats:$flightNo@${_dayKey(date)}'));
    return {
      for (final s in CabinLayout.build())
        if (rng.nextDouble() < 0.4) s.id,
    };
  }

  /// Seats for a flight (occupancy from its first leg), with [keepFree] forced free.
  static List<Seat> cabinFor(Flight f, {Set<String> keepFree = const {}}) {
    final occ = occupiedSeats(f.legs.first.flightNo, f.departure).difference(keepFree);
    return CabinLayout.build(occupied: occ);
  }

  // ---- The seeded demo booking -------------------------------------------

  static const samplePnr = 'K7Q2ZP';
  static const sampleRfidTag = '6E-RFID-0011523';
  static const samplePassenger =
      Passenger(id: 'pax-kishan', firstName: 'Kishan', lastName: 'Ojha', age: 24, frequentFlyerNo: 'FF-7023418');

  /// DEL→BOM departing about 20 h after [now] (web check-in open), Classic, seat 14C.
  static Booking sampleBooking(DateTime now) {
    final base = DateTime(now.year, now.month, now.day, now.hour, now.minute - now.minute % 5);
    final dep = base.add(const Duration(hours: 20));
    final flight = Flight(
      id: '6E2175_sample_DELBOM',
      baseFare: 5450,
      legs: [
        FlightLeg(
          flightNo: '6E 2175',
          from: 'DEL',
          to: 'BOM',
          departure: dep,
          arrival: dep.add(const Duration(hours: 2, minutes: 10)),
        ),
      ],
    );
    final seg = BookedSegment(
      flight: flight,
      family: FareFamily.classic,
      seats: {samplePassenger.id: '14C'},
      meals: {samplePassenger.id: 'm01'},
    );
    return Booking(
      pnr: samplePnr,
      bookedAt: now.subtract(const Duration(days: 3)),
      passengers: const [samplePassenger],
      segments: [seg],
      addOns: const {},
      fare: PricingEngine.quote(
        segments: [seg],
        passengers: 1,
        addOns: const {},
        today: now,
        mealsById: mealsById,
        seatsById: CabinLayout.seatsById,
      ),
    );
  }

  /// The sample booking's one checked bag (no scans yet).
  static List<Bag> sampleBags() => [
        Bag(rfidTag: sampleRfidTag, pnr: samplePnr, passengerId: samplePassenger.id, from: 'DEL', to: 'BOM'),
      ];

  /// Default profile on first launch.
  static const defaultProfile = samplePassenger;

  static const defaultSavedTravellers = <Passenger>[
    Passenger(id: 'st-anita', firstName: 'Anita', lastName: 'Ojha', age: 48),
  ];
}
