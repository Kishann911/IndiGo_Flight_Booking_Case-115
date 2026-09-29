/// Price lines of a quote or booking, in whole rupees.
class FareBreakdown {
  final int baseFare;
  final int familyCharges;
  final int seatFees;
  final int mealCharges;
  final int addOnCharges;
  final int taxesAndFees;
  final int total;

  const FareBreakdown({
    required this.baseFare,
    required this.familyCharges,
    required this.seatFees,
    required this.mealCharges,
    required this.addOnCharges,
    required this.taxesAndFees,
    required this.total,
  });

  static const zero = FareBreakdown(
    baseFare: 0,
    familyCharges: 0,
    seatFees: 0,
    mealCharges: 0,
    addOnCharges: 0,
    taxesAndFees: 0,
    total: 0,
  );

  Map<String, dynamic> toJson() => {
        'baseFare': baseFare,
        'familyCharges': familyCharges,
        'seatFees': seatFees,
        'mealCharges': mealCharges,
        'addOnCharges': addOnCharges,
        'taxesAndFees': taxesAndFees,
        'total': total,
      };

  factory FareBreakdown.fromJson(Map<String, dynamic> j) => FareBreakdown(
        baseFare: j['baseFare'] as int,
        familyCharges: j['familyCharges'] as int,
        seatFees: j['seatFees'] as int,
        mealCharges: j['mealCharges'] as int,
        addOnCharges: j['addOnCharges'] as int,
        taxesAndFees: j['taxesAndFees'] as int,
        total: j['total'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is FareBreakdown &&
      other.baseFare == baseFare &&
      other.familyCharges == familyCharges &&
      other.seatFees == seatFees &&
      other.mealCharges == mealCharges &&
      other.addOnCharges == addOnCharges &&
      other.taxesAndFees == taxesAndFees &&
      other.total == total;

  @override
  int get hashCode =>
      Object.hash(baseFare, familyCharges, seatFees, mealCharges, addOnCharges, taxesAndFees, total);

  @override
  String toString() => 'FareBreakdown(base $baseFare, family $familyCharges, seats $seatFees, '
      'meals $mealCharges, addOns $addOnCharges, taxes $taxesAndFees, total $total)';
}
