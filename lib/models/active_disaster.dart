class ActiveDisaster {
  const ActiveDisaster({required this.id, required this.name});

  final String id;
  final String name;

  static ActiveDisaster? fromResponse(dynamic json) {
    if (json is! Map<String, dynamic> || !json.containsKey('disaster')) {
      throw const FormatException('Expected disaster response');
    }
    final disaster = json['disaster'];
    if (disaster == null) return null;
    if (disaster is! Map<String, dynamic>) {
      throw const FormatException('Expected disaster object');
    }
    final id = disaster['id'];
    final name = disaster['name'];
    final status = disaster['status'];
    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        (status != 'active' && status != 'closed')) {
      throw const FormatException('Invalid disaster data');
    }
    return status == 'active' ? ActiveDisaster(id: id, name: name) : null;
  }
}
