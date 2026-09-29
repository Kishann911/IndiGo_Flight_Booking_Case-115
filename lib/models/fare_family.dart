enum FareFamily { lite, classic, flex }

/// Static description of what each fare family includes.
class FareFamilyInfo {
  final FareFamily family;
  final String name;
  final String tagline;
  final int handBaggageKg;

  /// 0 means no check-in bag.
  final int checkInBaggageKg;
  final bool mealIncluded;

  /// Amount added per passenger per segment on top of the dynamic base fare.
  final int charge;

  /// Rupees; 0 means free.
  final int changeFee;
  final bool changeFeePlusFareDifference;

  /// Rupees per segment; 0 for Flex (free until [freeCancellationCutoff]).
  final int cancellationFee;

  /// Flex only: free cancellation until this long before departure.
  final Duration? freeCancellationCutoff;
  final bool freeStandardSeat;

  const FareFamilyInfo._({
    required this.family,
    required this.name,
    required this.tagline,
    required this.handBaggageKg,
    required this.checkInBaggageKg,
    required this.mealIncluded,
    required this.charge,
    required this.changeFee,
    required this.changeFeePlusFareDifference,
    required this.cancellationFee,
    required this.freeCancellationCutoff,
    required this.freeStandardSeat,
  });

  static const lite = FareFamilyInfo._(
    family: FareFamily.lite,
    name: 'Lite',
    tagline: 'Hand baggage only',
    handBaggageKg: 7,
    checkInBaggageKg: 0,
    mealIncluded: false,
    charge: 0,
    changeFee: 2999,
    changeFeePlusFareDifference: true,
    cancellationFee: 3999,
    freeCancellationCutoff: null,
    freeStandardSeat: false,
  );

  static const classic = FareFamilyInfo._(
    family: FareFamily.classic,
    name: 'Classic',
    tagline: '1 check-in bag + meal',
    handBaggageKg: 7,
    checkInBaggageKg: 15,
    mealIncluded: true,
    charge: 800,
    changeFee: 1999,
    changeFeePlusFareDifference: false,
    cancellationFee: 2999,
    freeCancellationCutoff: null,
    freeStandardSeat: false,
  );

  static const flex = FareFamilyInfo._(
    family: FareFamily.flex,
    name: 'Flex',
    tagline: 'Full flexibility',
    handBaggageKg: 7,
    checkInBaggageKg: 15,
    mealIncluded: true,
    charge: 2200,
    changeFee: 0,
    changeFeePlusFareDifference: false,
    cancellationFee: 0,
    freeCancellationCutoff: Duration(hours: 2),
    freeStandardSeat: true,
  );

  static const all = [lite, classic, flex];

  static FareFamilyInfo of(FareFamily f) => switch (f) {
        FareFamily.lite => lite,
        FareFamily.classic => classic,
        FareFamily.flex => flex,
      };

  bool get hasCheckInBag => checkInBaggageKg > 0;

  String get baggageText => hasCheckInBag
      ? '$handBaggageKg kg hand + $checkInBaggageKg kg check-in'
      : '$handBaggageKg kg hand baggage only';

  String get mealText => mealIncluded ? '1 complimentary meal' : 'Meal not included (pre-order available)';

  String get changeText => switch (family) {
        FareFamily.lite => 'Change fee ₹2,999 + fare difference',
        FareFamily.classic => 'Change fee ₹1,999',
        FareFamily.flex => 'Free date change',
      };

  String get cancellationText => switch (family) {
        FareFamily.lite => 'Cancellation fee ₹3,999',
        FareFamily.classic => 'Cancellation fee ₹2,999',
        FareFamily.flex => 'Free cancellation up to 2 h before departure',
      };

  String get seatText => freeStandardSeat ? 'Free standard seat' : 'Seat selection from ₹199';

  /// Bullet list for comparison cards.
  List<String> get features => [baggageText, mealText, changeText, cancellationText, seatText];
}

extension FareFamilyX on FareFamily {
  FareFamilyInfo get info => FareFamilyInfo.of(this);
  String get label => info.name;
}
