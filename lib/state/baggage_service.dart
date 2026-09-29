import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/sample_data.dart';
import '../models/models.dart';
import 'notification_store.dart';

/// Simulated RFID baggage tracking (in memory, not persisted).
/// Seeds the sample booking's bag. No timer runs unless [startAutoScan].
class BaggageService extends ChangeNotifier {
  BaggageService({
    this.notifications,
    DateTime Function()? clock,
    Random? random,
    List<Bag>? initialBags,
  })  : clock = clock ?? DateTime.now,
        _random = random ?? Random() {
    _bags.addAll(initialBags ?? SampleData.sampleBags());
  }

  final NotificationStore? notifications;
  final DateTime Function() clock;
  final Random _random;
  final List<Bag> _bags = [];
  Timer? _timer;

  List<Bag> get bags => List.unmodifiable(_bags);
  List<Bag> bagsFor(String pnr) => _bags.where((b) => b.pnr == pnr.toUpperCase()).toList();

  Bag? bag(String rfidTag) {
    for (final b in _bags) {
      if (b.rfidTag == rfidTag) return b;
    }
    return null;
  }

  bool get isAutoScanning => _timer?.isActive ?? false;

  /// Creates one bag per passenger when the booking includes a check-in bag
  /// (Classic/Flex, or an extra-baggage add-on). Idempotent and silent (no
  /// notifyListeners), so it is safe to call from initState/build.
  List<Bag> ensureBagsForBooking(Booking b) {
    final entitled = b.segments.any((s) => s.family.info.hasCheckInBag) || b.addOns.any((a) => a.isBaggage);
    if (entitled && !b.isCancelled) {
      for (final p in b.passengers) {
        if (_bags.any((x) => x.pnr == b.pnr && x.passengerId == p.id)) continue;
        _bags.add(Bag(rfidTag: _newTag(), pnr: b.pnr, passengerId: p.id, from: b.from, to: b.to));
      }
    }
    return bagsFor(b.pnr);
  }

  String _newTag() {
    while (true) {
      final tag = '6E-RFID-${1000000 + _random.nextInt(9000000)}';
      if (bag(tag) == null) return tag;
    }
  }

  /// Location text for a stage, e.g. "DEL T1 — Counter 14".
  String locationFor(Bag bag, BagScanStage stage) {
    final sample = bag.rfidTag == SampleData.sampleRfidTag;
    final h = SampleData.stableHash(bag.rfidTag);
    final counter = sample ? 14 : 1 + h % 30;
    final xray = sample ? 3 : 1 + h % 6;
    final belt = sample ? 5 : 1 + h % 9;
    const letters = 'ABCDEFGHJKLMNPRSTUVWXYZ';
    final reg = sample ? 'VT-IZA' : 'VT-I${letters[h % letters.length]}${letters[(h ~/ 31) % letters.length]}';
    return switch (stage) {
      BagScanStage.checkedIn => '${bag.from} T1 — Counter $counter',
      BagScanStage.securityScreened => '${bag.from} — Security X-ray $xray',
      BagScanStage.loadedOnAircraft => 'Aircraft $reg hold',
      BagScanStage.unloadedAtDestination => '${bag.to} T1 — Arrivals',
      BagScanStage.onBelt => '${bag.to} — Belt $belt',
      BagScanStage.collected => 'Collected',
    };
  }

  /// Records the next RFID scan. Returns null when the tag is unknown or the
  /// bag is already collected.
  BagScan? scanNext(String rfidTag) {
    final i = _bags.indexWhere((b) => b.rfidTag == rfidTag);
    if (i < 0) return null;
    final b = _bags[i];
    final stage = b.nextStage;
    if (stage == null) return null;
    final scan = BagScan(stage: stage, location: locationFor(b, stage), at: clock());
    _bags[i] = b.copyWith(scans: [...b.scans, scan]);
    notifyListeners();
    notifications?.push(
      title: 'Bag ${stage.label.toLowerCase()} · $rfidTag',
      body: 'RFID scan (simulated): ${stage.label} — ${scan.location}.',
      kind: NotificationKind.baggage,
    );
    return scan;
  }

  /// Demo only: scans the first uncollected bag every [interval]; stops by
  /// itself when every bag is collected.
  void startAutoScan({Duration interval = const Duration(seconds: 6)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      final next = _bags.where((b) => !b.isCollected).firstOrNull;
      if (next == null) {
        stopAutoScan();
        return;
      }
      scanNext(next.rfidTag);
    });
    notifyListeners();
  }

  void stopAutoScan() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
