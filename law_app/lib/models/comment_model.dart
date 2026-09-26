import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorType;
  final String content;
  final String createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorType = 'user',
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Advocate',
      authorType: json['authorType']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  @override
  List<Object?> get props => [id, postId, authorId, content, createdAt];
}

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

