class Video {
  final String id;
  final String title;
  final String description; 
  final String url;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
    );
  }
}
