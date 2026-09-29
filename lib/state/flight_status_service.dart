import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/sample_data.dart';
import '../logic/formatters.dart';
import '../models/models.dart';
import 'notification_store.dart';

/// Simulated real-time flight tracking. Nothing runs until [start] is
/// called (only main() does that); tests drive it with [tick] and the hooks.
class FlightStatusService extends ChangeNotifier {
  FlightStatusService({
    this.notifications,
    DateTime Function()? clock,
    Random? random,
    this.eventProbability = 0.04,
  })  : clock = clock ?? DateTime.now,
        _random = random ?? Random();

  final NotificationStore? notifications;
  final DateTime Function() clock;
  final Random _random;

  /// Chance per tick per pre-departure flight of a random delay, and
  /// (separately) of a random gate change.
  final double eventProbability;

  final Map<String, FlightTracking> _tracking = {};
  final Map<String, List<TrackingEvent>> _events = {};
  Timer? _timer;
  int _ticks = 0;

  /// Tracking is keyed by `flightNo@yyyy-MM-dd` so the same flight number on
  /// two dates (e.g. a round trip) is tracked separately.
  static String keyFor(String flightNo, DateTime departure) =>
      '$flightNo@${departure.year}-${departure.month.toString().padLeft(2, '0')}-${departure.day.toString().padLeft(2, '0')}';

  /// The map key for [flightNo]: exact when [date] is given, otherwise the
  /// earliest tracked date of that flight number.
  String? _find(String flightNo, DateTime? date) {
    if (date != null) {
      final k = keyFor(flightNo, date);
      return _tracking.containsKey(k) ? k : null;
    }
    String? best;
    for (final e in _tracking.entries) {
      if (e.value.flightNo != flightNo) continue;
      if (best == null || e.value.scheduledDeparture.isBefore(_tracking[best]!.scheduledDeparture)) best = e.key;
    }
    return best;
  }

  List<FlightTracking> get tracked => List.unmodifiable(_tracking.values);

  /// Tracking for [flightNo] (on [date] if given, else its earliest tracked date).
  FlightTracking? tracking(String flightNo, {DateTime? date}) {
    final k = _find(flightNo, date);
    return k == null ? null : _tracking[k];
  }

  bool get isRunning => _timer?.isActive ?? false;
  int get tickCount => _ticks;

  /// Oldest first.
  List<TrackingEvent> eventsFor(String flightNo, {DateTime? date}) {
    final k = _find(flightNo, date);
    return List.unmodifiable(k == null ? const <TrackingEvent>[] : _events[k] ?? const []);
  }

  /// Gets or silently creates (no notifyListeners, so it is safe in build)
  /// the tracking entry for a flight number.
  FlightTracking trackingFor(String flightNo, DateTime scheduledDep, DateTime scheduledArr) {
    final key = keyFor(flightNo, scheduledDep);
    final existing = _tracking[key];
    if (existing != null) return existing;
    final gate = '${1 + SampleData.stableHash('gate:$flightNo') % 52}';
    final t = _recompute(FlightTracking(
      flightNo: flightNo,
      status: FlightStatus.scheduled,
      gate: gate,
      delayMinutes: 0,
      progress: 0,
      estimatedDeparture: scheduledDep,
      estimatedArrival: scheduledArr,
      scheduledDeparture: scheduledDep,
      scheduledArrival: scheduledArr,
    ));
    _tracking[key] = t;
    _events[key] = [
      TrackingEvent(
        at: clock(),
        text: 'Tracking started · scheduled ${Fmt.time(scheduledDep)} from gate $gate',
        kind: 'status',
      ),
    ];
    return t;
  }

  /// Tracks every leg of a confirmed booking (silent).
  void trackBooking(Booking b) {
    if (b.isCancelled) return;
    for (final s in b.segments) {
      for (final l in s.flight.legs) {
        trackingFor(l.flightNo, l.departure, l.arrival);
      }
    }
  }

  void start({Duration tick = const Duration(seconds: 5)}) {
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) => this.tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// One simulation step: random events (pre-departure only), then status
  /// and progress from the clock.
  void tick() {
    _ticks++;
    if (_tracking.isEmpty) return;
    for (final key in _tracking.keys.toList()) {
      var t = _tracking[key]!;
      final preDeparture = t.status == FlightStatus.scheduled ||
          t.status == FlightStatus.delayed ||
          t.status == FlightStatus.boarding;
      if (preDeparture && eventProbability > 0) {
        if (_random.nextDouble() < eventProbability) {
          simulateDelay(t.flightNo, _random.nextBool() ? 15 : 30, notify: false, date: t.scheduledDeparture);
        } else if (_random.nextDouble() < eventProbability) {
          simulateGateChange(t.flightNo, nextGate(t.flightNo, date: t.scheduledDeparture),
              notify: false, date: t.scheduledDeparture);
        }
        t = _tracking[key]!;
      }
      _setWithTransition(key, _recompute(t));
    }
    notifyListeners();
  }

  /// Adds [minutes] of delay (deterministic test/demo hook). Returns false
  /// when [flightNo] is not tracked. [date] picks the day of the flight.
  bool simulateDelay(String flightNo, int minutes, {bool notify = true, DateTime? date}) {
    final key = _find(flightNo, date);
    final t = key == null ? null : _tracking[key];
    if (key == null || t == null) return false;
    final delay = t.delayMinutes + minutes;
    final updated = _recompute(t.copyWith(
      delayMinutes: delay,
      estimatedDeparture: t.scheduledDeparture.add(Duration(minutes: delay)),
      estimatedArrival: t.scheduledArrival.add(Duration(minutes: delay)),
    ));
    _tracking[key] = updated;
    final text = '$flightNo delayed by $minutes min · new departure ${Fmt.time(updated.estimatedDeparture)}';
    _log(key, text, 'delay');
    notifications?.push(title: 'Flight delayed · $flightNo', body: text, kind: NotificationKind.delay);
    if (notify) notifyListeners();
    return true;
  }

  /// Moves the flight to [gate]. Returns false when not tracked.
  bool simulateGateChange(String flightNo, String gate, {bool notify = true, DateTime? date}) {
    final key = _find(flightNo, date);
    final t = key == null ? null : _tracking[key];
    if (key == null || t == null) return false;
    final old = t.gate;
    _tracking[key] = t.copyWith(gate: gate);
    final text = '$flightNo gate changed from $old to $gate';
    _log(key, text, 'gate');
    notifications?.push(title: 'Gate change · $flightNo', body: text, kind: NotificationKind.gate);
    if (notify) notifyListeners();
    return true;
  }

  /// A random gate different from the current one (for the demo button).
  String nextGate(String flightNo, {DateTime? date}) {
    final current = tracking(flightNo, date: date)?.gate;
    while (true) {
      final g = '${1 + _random.nextInt(52)}';
      if (g != current) return g;
    }
  }

  void _setWithTransition(String key, FlightTracking next) {
    final prev = _tracking[key]!;
    _tracking[key] = next;
    if (prev.status == next.status) return;
    final no = next.flightNo;
    _log(key, '$no · ${next.status.label}', 'status');
    if (next.status == FlightStatus.boarding) {
      notifications?.push(
        title: 'Boarding · $no',
        body: '$no is now boarding at gate ${next.gate}.',
        kind: NotificationKind.boarding,
      );
    }
  }

  void _log(String no, String text, String kind) =>
      (_events[no] ??= []).add(TrackingEvent(at: clock(), text: text, kind: kind));

  FlightTracking _recompute(FlightTracking t) {
    if (t.status == FlightStatus.cancelled) return t;
    final now = clock();
    final dep = t.estimatedDeparture, arr = t.estimatedArrival;
    final total = arr.difference(dep).inSeconds;
    double prog() => total <= 0 ? 1 : (now.difference(dep).inSeconds / total).clamp(0.0, 1.0);
    if (now.isBefore(dep.subtract(const Duration(minutes: 45)))) {
      return t.copyWith(status: t.delayMinutes > 0 ? FlightStatus.delayed : FlightStatus.scheduled, progress: 0);
    }
    if (now.isBefore(dep)) return t.copyWith(status: FlightStatus.boarding, progress: 0);
    if (now.isBefore(dep.add(const Duration(minutes: 10)))) {
      return t.copyWith(status: FlightStatus.departed, progress: prog());
    }
    if (now.isBefore(arr)) return t.copyWith(status: FlightStatus.enRoute, progress: prog());
    return t.copyWith(status: FlightStatus.landed, progress: 1.0);
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
