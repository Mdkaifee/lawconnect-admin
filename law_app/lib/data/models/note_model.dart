import 'package:equatable/equatable.dart';

class NoteModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? refType; // 'case' / 'section' / 'general'
  final String? refId;
  final String? refTitle;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.refType = 'general',
    this.refId,
    this.refTitle,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      date = json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return NoteModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      refType: json['refType']?.toString() ?? 'general',
      refId: json['refId']?.toString(),
      refTitle: json['refTitle']?.toString(),
      updatedAt: date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'title': title,
      'content': content,
      'refType': refType,
      'refId': refId,
      'refTitle': refTitle,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, content, refType, refId, refTitle, updatedAt];
}
