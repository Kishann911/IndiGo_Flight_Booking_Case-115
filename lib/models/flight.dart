/// One non-stop hop operated by a single flight number.
class FlightLeg {
  final String flightNo;
  final String from;
  final String to;
  final DateTime departure;
  final DateTime arrival;
  final String aircraft;

  const FlightLeg({
    required this.flightNo,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    this.aircraft = 'A320neo',
  });

  Duration get duration => arrival.difference(departure);

  Map<String, dynamic> toJson() => {
        'flightNo': flightNo,
        'from': from,
        'to': to,
        'departure': departure.toIso8601String(),
        'arrival': arrival.toIso8601String(),
        'aircraft': aircraft,
      };

  factory FlightLeg.fromJson(Map<String, dynamic> j) => FlightLeg(
        flightNo: j['flightNo'] as String,
        from: j['from'] as String,
        to: j['to'] as String,
        departure: DateTime.parse(j['departure'] as String),
        arrival: DateTime.parse(j['arrival'] as String),
        aircraft: (j['aircraft'] as String?) ?? 'A320neo',
      );
}

/// A bookable itinerary for one search segment: one leg (non-stop) or
/// two legs (one stop via a hub). [baseFare] is the undiscounted Lite fare
/// in rupees per passenger, before the booking-window multiplier.
class Flight {
  final String id;
  final List<FlightLeg> legs;
  final int baseFare;

  const Flight({required this.id, required this.legs, required this.baseFare})
      : assert(legs.length > 0);

  String get from => legs.first.from;
  String get to => legs.last.to;
  DateTime get departure => legs.first.departure;
  DateTime get arrival => legs.last.arrival;
  Duration get totalDuration => arrival.difference(departure);
  int get stops => legs.length - 1;

  /// Gap between consecutive legs (empty for non-stop).
  List<Duration> get layovers => [
        for (var i = 1; i < legs.length; i++)
          legs[i].departure.difference(legs[i - 1].arrival),
      ];

  /// Airports where the flight stops (empty for non-stop).
  List<String> get viaAirports => [for (var i = 1; i < legs.length; i++) legs[i].from];

  /// "6E 2134" or "6E 2134 / 6E 571".
  String get flightNos => legs.map((l) => l.flightNo).join(' / ');

  Map<String, dynamic> toJson() => {
        'id': id,
        'baseFare': baseFare,
        'legs': legs.map((l) => l.toJson()).toList(),
      };

  factory Flight.fromJson(Map<String, dynamic> j) => Flight(
        id: j['id'] as String,
        baseFare: j['baseFare'] as int,
        legs: (j['legs'] as List)
            .map((e) => FlightLeg.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  @override
  bool operator ==(Object other) => other is Flight && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Flight($id)';
}
