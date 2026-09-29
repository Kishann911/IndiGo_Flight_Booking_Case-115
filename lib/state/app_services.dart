import 'dart:math';

import 'baggage_service.dart';
import 'booking_store.dart';
import 'flight_status_service.dart';
import 'notification_store.dart';
import 'profile_store.dart';

/// All app state, created and loaded together. Starts no timers:
/// main() calls `flightStatus.start()`; widget tests must not.
class AppServices {
  final NotificationStore notifications;
  final BookingStore bookings;
  final ProfileStore profile;
  final FlightStatusService flightStatus;
  final BaggageService baggage;

  AppServices({
    required this.notifications,
    required this.bookings,
    required this.profile,
    required this.flightStatus,
    required this.baggage,
  });

  /// Builds every store with the same injectable [clock]/[random], awaits all
  /// `load()`s and tracks the flights of existing bookings.
  static Future<AppServices> create({DateTime Function()? clock, Random? random}) async {
    final notifications = NotificationStore(clock: clock, random: random);
    final bookings = BookingStore(notifications: notifications, clock: clock, random: random);
    final profile = ProfileStore(clock: clock, random: random);
    await Future.wait([notifications.load(), bookings.load(), profile.load()]);
    final flightStatus = FlightStatusService(notifications: notifications, clock: clock, random: random);
    for (final b in bookings.bookings) {
      flightStatus.trackBooking(b);
    }
    // Bookings confirmed later are tracked too.
    bookings.onBookingConfirmed = flightStatus.trackBooking;
    final baggage = BaggageService(notifications: notifications, clock: clock, random: random);
    return AppServices(
      notifications: notifications,
      bookings: bookings,
      profile: profile,
      flightStatus: flightStatus,
      baggage: baggage,
    );
  }
}
