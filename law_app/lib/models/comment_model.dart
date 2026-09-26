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
