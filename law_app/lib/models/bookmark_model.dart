import 'package:equatable/equatable.dart';

class BookmarkModel extends Equatable {
  final String id;
  final String refType; // 'case' | 'section' | 'post' | 'note'
  final String refId;
  final String title;
  final String? subtitle;

  const BookmarkModel({
    required this.id,
    required this.refType,
    required this.refId,
    required this.title,
    this.subtitle,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      refType: json['refType']?.toString() ?? 'case',
      refId: json['refId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, refType, refId, title, subtitle];
}
