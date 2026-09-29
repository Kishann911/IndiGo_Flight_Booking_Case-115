enum SeatTier { xl, front, standard, standardMiddle }

extension SeatTierX on SeatTier {
  int get price => switch (this) {
        SeatTier.xl => 799,
        SeatTier.front => 449,
        SeatTier.standard => 299,
        SeatTier.standardMiddle => 199,
      };

  String get label => switch (this) {
        SeatTier.xl => 'XL seat',
        SeatTier.front => 'Front row',
        SeatTier.standard => 'Standard (window/aisle)',
        SeatTier.standardMiddle => 'Standard (middle)',
      };

  /// Legroom description shown in the legend and seat sheet.
  String get legroom => switch (this) {
        SeatTier.xl => 'Extra legroom, 34–36 in pitch',
        SeatTier.front => 'Front rows, quick exit',
        SeatTier.standard || SeatTier.standardMiddle => '28–29 in pitch',
      };

  /// Seat is free under Flex.
  bool get isStandard => this == SeatTier.standard || this == SeatTier.standardMiddle;
}

/// One seat of the A320neo cabin. [id] is e.g. "12A".
class Seat {
  final String id;
  final int row;
  final String letter;
  final SeatTier tier;
  final bool occupied;

  const Seat({
    required this.id,
    required this.row,
    required this.letter,
    required this.tier,
    this.occupied = false,
  });

  factory Seat.at(int row, String letter, {bool occupied = false}) => Seat(
        id: '$row$letter',
        row: row,
        letter: letter,
        tier: CabinLayout.tierFor(row, letter),
        occupied: occupied,
      );

  /// Parses "12A". Returns null for malformed ids or seats outside the cabin.
  static Seat? tryParse(String id) {
    final m = RegExp(r'^(\d{1,2})([A-F])$').firstMatch(id.trim().toUpperCase());
    if (m == null) return null;
    final row = int.parse(m.group(1)!);
    if (row < 1 || row > CabinLayout.rows) return null;
    return Seat.at(row, m.group(2)!);
  }

  bool get isWindow => letter == 'A' || letter == 'F';
  bool get isAisle => letter == 'C' || letter == 'D';
  bool get isMiddle => letter == 'B' || letter == 'E';
  String get position => isWindow ? 'Window' : (isAisle ? 'Aisle' : 'Middle');
  int get price => tier.price;

  Seat copyWith({bool? occupied}) =>
      Seat(id: id, row: row, letter: letter, tier: tier, occupied: occupied ?? this.occupied);

  @override
  bool operator ==(Object other) => other is Seat && other.id == id && other.occupied == occupied;

  @override
  int get hashCode => Object.hash(id, occupied);

  @override
  String toString() => 'Seat($id${occupied ? ', occupied' : ''})';
}

/// A320neo layout: 30 rows x A–F, aisle between C and D.
class CabinLayout {
  CabinLayout._();

  static const int rows = 30;
  static const List<String> letters = ['A', 'B', 'C', 'D', 'E', 'F'];
  static const List<String> leftBlock = ['A', 'B', 'C'];
  static const List<String> rightBlock = ['D', 'E', 'F'];
  static const Set<int> xlRows = {1, 12, 13};

  /// Over-wing exit rows (also XL).
  static const Set<int> exitRows = {12, 13};

  static SeatTier tierFor(int row, String letter) {
    if (xlRows.contains(row)) return SeatTier.xl;
    if (row >= 2 && row <= 5) return SeatTier.front;
    if (letter == 'B' || letter == 'E') return SeatTier.standardMiddle;
    return SeatTier.standard;
  }

  /// All 180 seats, row-major, with [occupied] ids marked.
  static List<Seat> build({Set<String> occupied = const {}}) => [
        for (var r = 1; r <= rows; r++)
          for (final l in letters) Seat.at(r, l, occupied: occupied.contains('$r$l')),
      ];

  static final Map<String, Seat> seatsById = {for (final s in build()) s.id: s};
}
