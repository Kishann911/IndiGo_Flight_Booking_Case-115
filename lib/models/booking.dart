import 'add_on.dart';
import 'fare_breakdown.dart';
import 'fare_family.dart';
import 'flight.dart';
import 'passenger.dart';

/// A flight chosen for one segment of a booking.
/// [seats] and [meals] are keyed by passenger id.
class BookedSegment {
  final Flight flight;
  final FareFamily family;
  final Map<String, String> seats;
  final Map<String, String> meals;

  const BookedSegment({
    required this.flight,
    required this.family,
    this.seats = const {},
    this.meals = const {},
  });

  BookedSegment copyWith({
    Flight? flight,
    FareFamily? family,
    Map<String, String>? seats,
    Map<String, String>? meals,
  }) =>
      BookedSegment(
        flight: flight ?? this.flight,
        family: family ?? this.family,
        seats: seats ?? this.seats,
        meals: meals ?? this.meals,
      );

  Map<String, dynamic> toJson() => {
        'flight': flight.toJson(),
        'family': family.name,
        'seats': seats,
        'meals': meals,
      };

  factory BookedSegment.fromJson(Map<String, dynamic> j) => BookedSegment(
        flight: Flight.fromJson(Map<String, dynamic>.from(j['flight'] as Map)),
        family: FareFamily.values.byName(j['family'] as String),
        seats: Map<String, String>.from((j['seats'] as Map?) ?? const {}),
        meals: Map<String, String>.from((j['meals'] as Map?) ?? const {}),
      );
}

enum BookingStatus { confirmed, cancelled }

class Booking {
  /// 6 characters from A–Z and 2–9.
  final String pnr;
  final DateTime bookedAt;
  final List<Passenger> passengers;
  final List<BookedSegment> segments;

  /// Per-passenger add-ons apply to every passenger.
  final Set<AddOnType> addOns;
  final FareBreakdown fare;
  final BookingStatus status;

  /// Key: [checkInKey] ("segIndex|passengerId").
  final Map<String, bool> checkedIn;

  const Booking({
    required this.pnr,
    required this.bookedAt,
    required this.passengers,
    required this.segments,
    required this.addOns,
    required this.fare,
    this.status = BookingStatus.confirmed,
    this.checkedIn = const {},
  });

  static String checkInKey(int segIndex, String passengerId) => '$segIndex|$passengerId';

  bool isCheckedIn(int segIndex, String passengerId) =>
      checkedIn[checkInKey(segIndex, passengerId)] ?? false;

  bool get isCancelled => status == BookingStatus.cancelled;
  String get from => segments.first.flight.from;
  String get to => segments.last.flight.to;
  DateTime get departure => segments.first.flight.departure;

  /// "DEL → BOM" or "DEL → BOM → GOI".
  String get routeLabel =>
      [segments.first.flight.from, ...segments.map((s) => s.flight.to)].join(' → ');

  Passenger? passengerById(String id) {
    for (final p in passengers) {
      if (p.id == id) return p;
    }
    return null;
  }

  Booking copyWith({
    List<Passenger>? passengers,
    List<BookedSegment>? segments,
    Set<AddOnType>? addOns,
    FareBreakdown? fare,
    BookingStatus? status,
    Map<String, bool>? checkedIn,
  }) =>
      Booking(
        pnr: pnr,
        bookedAt: bookedAt,
        passengers: passengers ?? this.passengers,
        segments: segments ?? this.segments,
        addOns: addOns ?? this.addOns,
        fare: fare ?? this.fare,
        status: status ?? this.status,
        checkedIn: checkedIn ?? this.checkedIn,
      );

  Map<String, dynamic> toJson() => {
        'pnr': pnr,
        'bookedAt': bookedAt.toIso8601String(),
        'passengers': passengers.map((p) => p.toJson()).toList(),
        'segments': segments.map((s) => s.toJson()).toList(),
        'addOns': addOns.map((a) => a.name).toList(),
        'fare': fare.toJson(),
        'status': status.name,
        'checkedIn': checkedIn,
      };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        pnr: j['pnr'] as String,
        bookedAt: DateTime.parse(j['bookedAt'] as String),
        passengers: (j['passengers'] as List)
            .map((e) => Passenger.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        segments: (j['segments'] as List)
            .map((e) => BookedSegment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        addOns: ((j['addOns'] as List?) ?? const [])
            .map((e) => AddOnType.values.byName(e as String))
            .toSet(),
        fare: FareBreakdown.fromJson(Map<String, dynamic>.from(j['fare'] as Map)),
        status: BookingStatus.values.byName(j['status'] as String),
        checkedIn: Map<String, bool>.from((j['checkedIn'] as Map?) ?? const {}),
      );

  @override
  String toString() => 'Booking($pnr, $routeLabel, ${status.name})';
}
