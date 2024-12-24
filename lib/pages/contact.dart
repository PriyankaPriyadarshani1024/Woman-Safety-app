class Contact {
  String id;
  String name;
  String contact;

  Contact({required this.id, required this.name, required this.contact});

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['\$id'],
      name: map['name'],
      contact: map['contact'],
    );
  }
}
