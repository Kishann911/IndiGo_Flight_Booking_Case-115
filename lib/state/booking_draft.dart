import '../models/models.dart';

/// Immutable in-progress booking. Screens read it via
/// `context.watch<BookingStore>().draft` and change it only through the
/// BookingStore draft mutators.
class BookingDraft {
  final List<Segment> segments;
  final int passengerCount;

  /// Chosen flight / family per segment index (null = not chosen yet).
  final List<Flight?> flights;
  final List<FareFamily?> families;
  final List<Passenger> passengers;

  /// Per segment index: passengerId → seatId / mealId.
  final List<Map<String, String>> seats;
  final List<Map<String, String>> meals;
  final Set<AddOnType> addOns;

  const BookingDraft({
    required this.segments,
    required this.passengerCount,
    required this.flights,
    required this.families,
    required this.passengers,
    required this.seats,
    required this.meals,
    required this.addOns,
  });

  factory BookingDraft.start(List<Segment> segments, int passengerCount) => BookingDraft(
        segments: List.unmodifiable(segments),
        passengerCount: passengerCount,
        flights: List.filled(segments.length, null),
        families: List.filled(segments.length, null),
        passengers: const [],
        seats: List.generate(segments.length, (_) => const <String, String>{}),
        meals: List.generate(segments.length, (_) => const <String, String>{}),
        addOns: const {},
      );

  int get segmentCount => segments.length;
  bool get allFlightsChosen => flights.every((f) => f != null) && families.every((f) => f != null);

  /// First segment index without a chosen flight, or null when all are chosen.
  int? get nextUnchosenSegment {
    for (var i = 0; i < flights.length; i++) {
      if (flights[i] == null || families[i] == null) return i;
    }
    return null;
  }

  bool get passengersComplete => passengers.length == passengerCount;
  bool get isComplete => allFlightsChosen && passengersComplete;

  String? seatFor(int segIndex, String passengerId) => seats[segIndex][passengerId];
  String? mealFor(int segIndex, String passengerId) => meals[segIndex][passengerId];
  bool hasAddOn(AddOnType t) => addOns.contains(t);

  /// Segments with a chosen flight, as BookedSegments (used for quoting).
  List<BookedSegment> get bookedSegments => [
        for (var i = 0; i < segments.length; i++)
          if (flights[i] != null && families[i] != null)
            BookedSegment(flight: flights[i]!, family: families[i]!, seats: seats[i], meals: meals[i]),
      ];

  BookingDraft copyWith({
    List<Flight?>? flights,
    List<FareFamily?>? families,
    List<Passenger>? passengers,
    List<Map<String, String>>? seats,
    List<Map<String, String>>? meals,
    Set<AddOnType>? addOns,
  }) =>
      BookingDraft(
        segments: segments,
        passengerCount: passengerCount,
        flights: flights ?? this.flights,
        families: families ?? this.families,
        passengers: passengers ?? this.passengers,
        seats: seats ?? this.seats,
        meals: meals ?? this.meals,
        addOns: addOns ?? this.addOns,
      );
}
