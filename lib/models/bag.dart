enum BagScanStage {
  checkedIn,
  securityScreened,
  loadedOnAircraft,
  unloadedAtDestination,
  onBelt,
  collected,
}

extension BagScanStageX on BagScanStage {
  String get label => switch (this) {
        BagScanStage.checkedIn => 'Checked in',
        BagScanStage.securityScreened => 'Security screened',
        BagScanStage.loadedOnAircraft => 'Loaded on aircraft',
        BagScanStage.unloadedAtDestination => 'Unloaded at destination',
        BagScanStage.onBelt => 'On belt',
        BagScanStage.collected => 'Collected',
      };
}

class BagScan {
  final BagScanStage stage;
  final String location;
  final DateTime at;

  const BagScan({required this.stage, required this.location, required this.at});
}

/// A checked bag with a (simulated) RFID tag such as "6E-RFID-0012345".
/// [from]/[to] are an extension over the spec (used for scan locations).
class Bag {
  final String rfidTag;
  final String pnr;
  final String passengerId;
  final String from;
  final String to;
  final List<BagScan> scans;

  const Bag({
    required this.rfidTag,
    required this.pnr,
    required this.passengerId,
    required this.from,
    required this.to,
    this.scans = const [],
  });

  BagScan? get lastScan => scans.isEmpty ? null : scans.last;
  BagScanStage? get stage => lastScan?.stage;
  bool get isCollected => stage == BagScanStage.collected;

  /// The stage the next RFID scan will record, or null when collected.
  BagScanStage? get nextStage {
    if (scans.isEmpty) return BagScanStage.values.first;
    final i = scans.last.stage.index + 1;
    return i < BagScanStage.values.length ? BagScanStage.values[i] : null;
  }

  Bag copyWith({List<BagScan>? scans}) => Bag(
        rfidTag: rfidTag,
        pnr: pnr,
        passengerId: passengerId,
        from: from,
        to: to,
        scans: scans ?? this.scans,
      );
}
