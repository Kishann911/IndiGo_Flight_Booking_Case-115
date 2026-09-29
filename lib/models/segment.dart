/// A search segment (one row of the search form).
class Segment {
  final String from;
  final String to;
  final DateTime date;

  const Segment({required this.from, required this.to, required this.date});

  Segment copyWith({String? from, String? to, DateTime? date}) =>
      Segment(from: from ?? this.from, to: to ?? this.to, date: date ?? this.date);

  @override
  bool operator ==(Object other) =>
      other is Segment && other.from == from && other.to == to && other.date == date;

  @override
  int get hashCode => Object.hash(from, to, date);

  @override
  String toString() => 'Segment($from-$to ${date.toIso8601String().substring(0, 10)})';
}
