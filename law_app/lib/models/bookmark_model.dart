import 'package:equatable/equatable.dart';

class BookmarkModel extends Equatable {
  final String id;
  final String refType;
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
    return BookmarkModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      refType: (json['refType'] ?? json['itemType'] ?? 'case').toString(),
      refId: (json['refId'] ?? json['itemId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: json['subtitle']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'refType': refType,
      'refId': refId,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, refType, refId, title, subtitle, createdAt];
}

