// models/fair_news.dart
class FairNews {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final DateTime publishDate;
  final DateTime? eventDate;
  final String? location;

  FairNews({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.publishDate,
    this.eventDate,
    this.location,
  });

  factory FairNews.fromJson(Map<String, dynamic> json) {
    return FairNews(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      publishDate: DateTime.parse(json['publishDate']),
      eventDate:
          json['eventDate'] != null ? DateTime.parse(json['eventDate']) : null,
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'publishDate': publishDate.toIso8601String(),
      'eventDate': eventDate?.toIso8601String(),
      'location': location,
    };
  }
}
