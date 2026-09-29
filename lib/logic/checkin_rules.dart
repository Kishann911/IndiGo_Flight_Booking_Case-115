import '../models/flight.dart';
import '../models/passenger.dart';

/// Web check-in window: opens 48 h before departure (inclusive) and closes
/// 60 min before departure (exclusive: at exactly 60 min it is closed).
class CheckInRules {
  CheckInRules._();

  static const Duration opensBefore = Duration(hours: 48);
  static const Duration closesBefore = Duration(minutes: 60);
  static const Duration boardingBefore = Duration(minutes: 45);

  static DateTime opensAt(DateTime departure) => departure.subtract(opensBefore);
  static DateTime closesAt(DateTime departure) => departure.subtract(closesBefore);

  static bool isOpen(DateTime departure, DateTime now) =>
      !now.isBefore(opensAt(departure)) && now.isBefore(closesAt(departure));

  /// "Opens in 3 d 4 h" / "Opens in 5 h 10 m" / "Open — closes in 5 h 10 m" / "Closed".
  static String windowLabel(DateTime departure, DateTime now) {
    if (now.isBefore(opensAt(departure))) {
      return 'Opens in ${_span(opensAt(departure).difference(now))}';
    }
    if (isOpen(departure, now)) {
      return 'Open — closes in ${_span(closesAt(departure).difference(now))}';
    }
    return 'Closed';
  }

  /// "3 d 4 h" when ≥ 1 day, else "5 h 10 m" (or "10 m").
  static String _span(Duration d) {
    if (d.inDays >= 1) return '${d.inDays} d ${d.inHours.remainder(24)} h';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '$h h $m m' : '$m m';
  }

  static DateTime boardingTime(DateTime departure) => departure.subtract(boardingBefore);

  /// Priority or rows 1–5 → 1; rows 6–17 → 2; otherwise 3.
  static int boardingZone(bool priority, String seatId) {
    if (priority) return 1;
    final row = int.tryParse(RegExp(r'^\d+').stringMatch(seatId.trim()) ?? '');
    if (row == null) return 3;
    if (row <= 5) return 1;
    if (row <= 17) return 2;
    return 3;
  }

  /// Day of year, 1–366.
  static int julianDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(d.year, 1, 1)).inDays + 1;

  /// BCBP-like QR payload:
  /// `M1{LAST}/{FIRST} E{PNR} {FROM}{TO}6E {NUMBER} {julianDay} Y {SEAT} {sequence}`
  /// e.g. "M1OJHA/KISHAN EK7Q2ZP DELBOM6E 2175 273 Y 014C 0001".
  /// NUMBER is 4 digits, julianDay 3 digits, SEAT 4 chars, sequence 4 digits.
  static String bcbpPayload({
    required Passenger passenger,
    required String pnr,
    required FlightLeg leg,
    required String seatId,
    required int sequence,
  }) {
    final number = leg.flightNo
        .replaceFirst(RegExp(r'^6E\s*'), '')
        .replaceAll(RegExp(r'[^0-9]'), '')
        .padLeft(4, '0');
    final jd = julianDay(leg.departure).toString().padLeft(3, '0');
    final seat = seatId.toUpperCase().padLeft(4, '0');
    final seq = sequence.toString().padLeft(4, '0');
    return 'M1${passenger.lastName.toUpperCase()}/${passenger.firstName.toUpperCase()} '
        'E${pnr.toUpperCase()} ${leg.from}${leg.to}6E $number $jd Y $seat $seq';
  }
}
