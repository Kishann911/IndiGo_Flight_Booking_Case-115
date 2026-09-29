/// A traveller on a booking; also used for the profile and saved travellers.
class Passenger {
  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final String? frequentFlyerNo;

  const Passenger({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    this.frequentFlyerNo,
  });

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isEmpty ? '' : firstName[0]}${lastName.isEmpty ? '' : lastName[0]}'.toUpperCase();

  Passenger copyWith({
    String? id,
    String? firstName,
    String? lastName,
    int? age,
    String? frequentFlyerNo,
    bool clearFrequentFlyerNo = false,
  }) =>
      Passenger(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        age: age ?? this.age,
        frequentFlyerNo: clearFrequentFlyerNo ? null : (frequentFlyerNo ?? this.frequentFlyerNo),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        if (frequentFlyerNo != null) 'frequentFlyerNo': frequentFlyerNo,
      };

  factory Passenger.fromJson(Map<String, dynamic> j) => Passenger(
        id: j['id'] as String,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        age: j['age'] as int,
        frequentFlyerNo: j['frequentFlyerNo'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is Passenger &&
      other.id == id &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.age == age &&
      other.frequentFlyerNo == frequentFlyerNo;

  @override
  int get hashCode => Object.hash(id, firstName, lastName, age, frequentFlyerNo);

  @override
  String toString() => 'Passenger($id, $fullName)';
}
