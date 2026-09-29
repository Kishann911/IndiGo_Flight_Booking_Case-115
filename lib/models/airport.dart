/// An airport served by the prototype's schedule.
class Airport {
  final String code;
  final String city;
  final String name;

  const Airport({required this.code, required this.city, required this.name});

  /// "Delhi (DEL)".
  String get label => '$city ($code)';

  @override
  bool operator ==(Object other) => other is Airport && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Airport($code)';
}
