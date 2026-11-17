class Shelter {
  const Shelter({
    required this.name,
    required this.distanceMeters,
    required this.capacity,
    required this.currentOccupancy,
    required this.isOverCapacity,
  });

  final String name;
  final double distanceMeters;
  final int capacity;
  final int currentOccupancy;
  final bool isOverCapacity;

  bool get isFull => isOverCapacity || currentOccupancy >= capacity;

  // OpenAPIのNearbyShelterから一覧表示に必要なフィールドを読み込む。
  factory Shelter.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final distance = json['distanceMeters'];
    final capacity = json['capacity'];
    final occupancy = json['currentOccupancy'];
    final overCapacity = json['isOverCapacity'];
    if (name is! String ||
        name.trim().isEmpty ||
        distance is! num ||
        !distance.isFinite ||
        distance < 0 ||
        capacity is! int ||
        capacity < 0 ||
        occupancy is! int ||
        occupancy < 0 ||
        overCapacity is! bool) {
      throw const FormatException('Invalid shelter data');
    }
    return Shelter(
      name: name,
      distanceMeters: distance.toDouble(),
      capacity: capacity,
      currentOccupancy: occupancy,
      isOverCapacity: overCapacity,
    );
  }
}
