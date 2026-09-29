enum FlightStatus { scheduled, boarding, departed, enRoute, landed, delayed, cancelled }

extension FlightStatusX on FlightStatus {
  String get label => switch (this) {
        FlightStatus.scheduled => 'Scheduled',
        FlightStatus.boarding => 'Boarding',
        FlightStatus.departed => 'Departed',
        FlightStatus.enRoute => 'En route',
        FlightStatus.landed => 'Landed',
        FlightStatus.delayed => 'Delayed',
        FlightStatus.cancelled => 'Cancelled',
      };
}

/// Simulated live state of one flight number.
class FlightTracking {
  final String flightNo;
  final FlightStatus status;
  final String gate;
  final int delayMinutes;

  /// 0–1 share of the flight completed.
  final double progress;
  final DateTime estimatedDeparture;
  final DateTime estimatedArrival;

  /// Extension over the spec: the timetable times the entry was created with.
  final DateTime scheduledDeparture;
  final DateTime scheduledArrival;

  const FlightTracking({
    required this.flightNo,
    required this.status,
    required this.gate,
    required this.delayMinutes,
    required this.progress,
    required this.estimatedDeparture,
    required this.estimatedArrival,
    required this.scheduledDeparture,
    required this.scheduledArrival,
  });

  FlightTracking copyWith({
    FlightStatus? status,
    String? gate,
    int? delayMinutes,
    double? progress,
    DateTime? estimatedDeparture,
    DateTime? estimatedArrival,
  }) =>
      FlightTracking(
        flightNo: flightNo,
        status: status ?? this.status,
        gate: gate ?? this.gate,
        delayMinutes: delayMinutes ?? this.delayMinutes,
        progress: progress ?? this.progress,
        estimatedDeparture: estimatedDeparture ?? this.estimatedDeparture,
        estimatedArrival: estimatedArrival ?? this.estimatedArrival,
        scheduledDeparture: scheduledDeparture,
        scheduledArrival: scheduledArrival,
      );

  @override
  String toString() => 'FlightTracking($flightNo, ${status.name}, gate $gate, +${delayMinutes}m)';
}

/// One line of a flight's event timeline (extension over the spec).
class TrackingEvent {
  final DateTime at;
  final String text;

  /// 'status', 'delay' or 'gate'.
  final String kind;

  const TrackingEvent({required this.at, required this.text, required this.kind});
}
