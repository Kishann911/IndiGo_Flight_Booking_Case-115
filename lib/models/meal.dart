/// A pre-orderable meal. [cuisine] is one of [Meal.cuisines];
/// [dietary] values come from [Meal.dietaryTags].
class Meal {
  final String id;
  final String name;
  final String cuisine;
  final Set<String> dietary;
  final int price;

  const Meal({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.dietary,
    required this.price,
  });

  static const List<String> cuisines = [
    'North Indian',
    'South Indian',
    'Continental',
    'Asian',
    'Snacks',
  ];

  static const List<String> dietaryTags = [
    'veg',
    'non-veg',
    'jain',
    'vegan',
    'gluten-free',
    'diabetic',
  ];

  bool get isVeg => dietary.contains('veg');

  @override
  String toString() => 'Meal($id)';
}
