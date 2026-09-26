import 'package:equatable/equatable.dart';

class BookmarkModel extends Equatable {
  final String id;
  final String refType; // 'case' / 'section' / 'post' / 'update'
  final String refId;
  final String title;
  final String? subtitle;
  final DateTime createdAt;

  const BookmarkModel({
    required this.id,
    required this.refType,
    required this.refId,
    required this.title,
    this.subtitle,
    required this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      date = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return BookmarkModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      refType: json['refType']?.toString() ?? 'case',
      refId: json['refId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      createdAt: date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'refType': refType,
      'refId': refId,
      'title': title,
      'subtitle': subtitle,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, refType, refId, title, subtitle, createdAt];
}
