import 'package:equatable/equatable.dart';

class LegalUpdateModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String source;
  final String court;
  final String badge;
  final String url;
  final DateTime publishedAt;

  const LegalUpdateModel({
    required this.id,
    required this.title,
    this.body = '',
    this.source = 'LiveLaw',
    this.court = 'Supreme Court',
    this.badge = 'SC',
    this.url = '',
    required this.publishedAt,
  });

  factory LegalUpdateModel.fromJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      date = json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'].toString())
          : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return LegalUpdateModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      source: json['source']?.toString() ?? 'LiveLaw',
      court: json['court']?.toString() ?? 'Supreme Court',
      badge: json['badge']?.toString() ?? (json['court'] == 'High Court' ? 'HC' : 'SC'),
      url: json['url']?.toString() ?? '',
      publishedAt: date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'title': title,
      'body': body,
      'source': source,
      'court': court,
      'badge': badge,
      'url': url,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, body, source, court, badge, url, publishedAt];
}
