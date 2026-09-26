import 'package:equatable/equatable.dart';

class PostModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String category;
  final String authorName;
  final String authorType;
  final String? authorId;
  final List<String> tags;
  final int likes;
  final int commentsCount;
  final DateTime createdAt;
  final bool isLiked;

  const PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'General Law',
    this.authorName = 'Rishikesh Yadav',
    this.authorType = 'admin',
    this.authorId,
    this.tags = const [],
    this.likes = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.isLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      date = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return PostModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General Law',
      authorName: json['authorName']?.toString() ?? 'Rishikesh Yadav',
      authorType: json['authorType']?.toString() ?? 'admin',
      authorId: json['authorId']?.toString(),
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      likes: json['likes'] is int ? json['likes'] : int.tryParse(json['likes']?.toString() ?? '') ?? 0,
      commentsCount: json['commentsCount'] is int
          ? json['commentsCount']
          : int.tryParse(json['commentsCount']?.toString() ?? '') ?? 0,
      createdAt: date,
      isLiked: json['isLiked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'title': title,
      'content': content,
      'category': category,
      'authorName': authorName,
      'authorType': authorType,
      'authorId': authorId,
      'tags': tags,
      'likes': likes,
      'commentsCount': commentsCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PostModel copyWith({
    int? likes,
    bool? isLiked,
  }) {
    return PostModel(
      id: id,
      title: title,
      content: content,
      category: category,
      authorName: authorName,
      authorType: authorType,
      authorId: authorId,
      tags: tags,
      likes: likes ?? this.likes,
      commentsCount: commentsCount,
      createdAt: createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        category,
        authorName,
        authorType,
        authorId,
        tags,
        likes,
        commentsCount,
        createdAt,
        isLiked,
      ];
}
