/// A user-defined organisational tag used for both budget trees AND goal
/// saplings. Each category has a display name + a hex colour stored as int.
/// The colour drives the leaf palette of trees in that category, making
/// "Trips" trees blue, "Emergency" trees red, etc.
class TreeCategory {
  final String id;
  String name;
  int colorValue;

  TreeCategory({
    String? id,
    required this.name,
    required this.colorValue,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
      };

  factory TreeCategory.fromJson(Map<String, dynamic> j) => TreeCategory(
        id: j['id'] as String,
        name: j['name'] as String,
        colorValue: (j['colorValue'] as num).toInt(),
      );
}
