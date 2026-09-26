import 'package:equatable/equatable.dart';

class NoteModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String refType;
  final String? refId;
  final String? refTitle;
  final String updatedAt;

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
    return NoteModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Note',
      content: json['content']?.toString() ?? '',
      refType: json['refType']?.toString() ?? 'general',
      refId: json['refId']?.toString(),
      refTitle: json['refTitle']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'refType': refType,
      'refId': refId,
      'refTitle': refTitle,
    };
  }

  @override
  List<Object?> get props => [id, title, content, refType, refId, updatedAt];
}
