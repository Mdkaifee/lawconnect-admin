import 'package:equatable/equatable.dart';

class PostModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? imageData;
  final String? imageMimeType;
  final String category;
  final List<String> tags;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String authorType; // 'admin' | 'user'
  final bool isAuthorPremium;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final String createdAt;

  const PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'General Law',
    this.tags = const [],
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    this.authorType = 'user',
    this.isAuthorPremium = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.imageData,
    this.imageMimeType,
  });

  factory PostModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final tagsList = (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    
    // Check if liked by current user
    final likedByList = json['likedBy'] as List<dynamic>?;
    bool liked = false;
    if (currentUserId != null && likedByList != null) {
      liked = likedByList.any((id) => id.toString() == currentUserId);
    } else if (json['isLiked'] == true) {
      liked = true;
    }

    return PostModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageData: json['imageData']?.toString().isNotEmpty == true ? json['imageData'].toString() : null,
      imageMimeType: json['imageMimeType']?.toString(),
      category: json['category']?.toString() ?? 'General Law',
      tags: tagsList,
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Advocate',
      authorPhotoUrl: json['authorPhotoUrl']?.toString(),
      authorType: json['authorType']?.toString() ?? 'user',
      isAuthorPremium: json['isAuthorPremium'] == true,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? (json['likes'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      isLiked: liked,
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  PostModel copyWith({
    int? likesCount,
    bool? isLiked,
    int? commentsCount,
  }) {
    return PostModel(
      id: id,
      title: title,
      content: content,
      category: category,
      tags: tags,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      authorType: authorType,
      isAuthorPremium: isAuthorPremium,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      imageData: imageData,
      imageMimeType: imageMimeType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        imageData,
        category,
        authorId,
        authorName,
        authorPhotoUrl,
        authorType,
        isAuthorPremium,
        likesCount,
        commentsCount,
        isLiked,
        createdAt,
      ];
}

