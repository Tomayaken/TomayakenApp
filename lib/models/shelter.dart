class Shelter {
  const Shelter({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.crowding,
    this.distanceMeters,
    this.address,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? crowding;
  final double? distanceMeters;
  final String? address;

  factory Shelter.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['shelterId'];
    final name = json['name'] ?? json['shelterName'];
    final latitude = json['latitude'] ?? json['lat'];
    final longitude = json['longitude'] ?? json['lng'] ?? json['lon'];
    if (id == null ||
        name == null ||
        latitude == null ||
        longitude == null) {
      throw const FormatException('避難所データに必須項目がありません。');
    }

    return Shelter(
      id: id.toString(),
      name: name.toString(),
      latitude: _asDouble(latitude),
      longitude: _asDouble(longitude),
      crowding: (json['crowding'] ?? json['congestion'] ?? json['status'])
          ?.toString(),
      distanceMeters: _asNullableDouble(
        json['distanceMeters'] ?? json['distance'],
      ),
      address: (json['address'] ?? json['location'])?.toString(),
    );
  }

  static double _asDouble(Object value) {
    final result = double.tryParse(value.toString());
    if (result == null || !result.isFinite) {
      throw const FormatException('緯度・経度が不正です。');
    }
    return result;
  }

  static double? _asNullableDouble(Object? value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}
