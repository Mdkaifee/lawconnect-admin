import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String headline;
  final String college;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isFriend;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.headline = '',
    this.college = '',
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFriend = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Advocate',
      email: json['email']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      headline: json['headline']?.toString() ?? '',
      college: json['college']?.toString() ?? '',
      postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      isFriend: json['isFriend'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'headline': headline,
      'college': college,
    };
  }

  @override
  List<Object?> get props => [id, name, email, photoUrl, headline, college, postsCount, followersCount, followingCount, isFriend];
}

