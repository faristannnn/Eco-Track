class Category {
  final String id;
  final String name;
  final String? kategori; 

  Category({
    required this.id,
    required this.name,
    this.kategori,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'],
      name: json['name'],
      kategori: json['kategori'],
    );
  }
}
