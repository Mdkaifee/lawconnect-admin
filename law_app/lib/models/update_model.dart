import 'package:equatable/equatable.dart';

class UpdateModel extends Equatable {
  final String id;
  final String title;
  final String? summary;
  final String? body;
  final String category;
  final String source;
  final String? sourceUrl;
  final String court;
  final String? badge;
  final String? publishedAt;
  final String verificationStatus;

  const UpdateModel({
    required this.id,
    required this.title,
    this.summary,
    this.body,
    this.category = 'General',
    this.source = 'Official Source',
    this.sourceUrl,
    this.court = 'Other',
    this.badge,
    this.publishedAt,
    this.verificationStatus = 'verified',
  });

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    return UpdateModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      body: json['body']?.toString(),
      category: json['category']?.toString() ?? 'General',
      source: json['source']?.toString() ?? 'Official Source',
      sourceUrl: json['sourceUrl']?.toString(),
      court: json['court']?.toString() ?? 'Other',
      badge: json['badge']?.toString(),
      publishedAt: json['publishedAt']?.toString() ?? json['createdAt']?.toString(),
      verificationStatus: json['verificationStatus']?.toString() ?? 'verified',
    );
  }

  @override
  List<Object?> get props => [id, title, summary, category, source, court, badge, publishedAt, verificationStatus];
}
