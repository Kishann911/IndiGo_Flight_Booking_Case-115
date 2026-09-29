enum AddOnType { extraBaggage5kg, extraBaggage10kg, priorityBoarding, loungeAccess }

extension AddOnTypeX on AddOnType {
  /// Unit price in rupees (per booking for baggage, per passenger otherwise).
  int get price => switch (this) {
        AddOnType.extraBaggage5kg => 1800,
        AddOnType.extraBaggage10kg => 3400,
        AddOnType.priorityBoarding => 299,
        AddOnType.loungeAccess => 1500,
      };

  bool get perPassenger => this == AddOnType.priorityBoarding || this == AddOnType.loungeAccess;

  bool get isBaggage => this == AddOnType.extraBaggage5kg || this == AddOnType.extraBaggage10kg;

  String get label => switch (this) {
        AddOnType.extraBaggage5kg => 'Extra baggage 5 kg',
        AddOnType.extraBaggage10kg => 'Extra baggage 10 kg',
        AddOnType.priorityBoarding => 'Priority boarding',
        AddOnType.loungeAccess => 'Lounge access',
      };

  String get description => switch (this) {
        AddOnType.extraBaggage5kg => 'Pre-paid excess baggage, per booking',
        AddOnType.extraBaggage10kg => 'Pre-paid excess baggage, per booking',
        AddOnType.priorityBoarding => 'Board first in zone 1, per passenger',
        AddOnType.loungeAccess => 'Departure lounge access, per passenger',
      };
}
