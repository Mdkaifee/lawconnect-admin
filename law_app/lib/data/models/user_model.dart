import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? headline;
  final String? college;
  final String? photoUrl;
  final bool blocked;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.headline,
    this.college,
    this.photoUrl,
    this.blocked = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Rishikesh Yadav',
      email: json['email']?.toString() ?? '',
      headline: json['headline']?.toString() ?? 'Law Student | Future Advocate',
      college: json['college']?.toString() ?? 'Galgotias University',
      photoUrl: json['photoUrl']?.toString(),
      blocked: json['blocked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'email': email,
      'headline': headline,
      'college': college,
      'photoUrl': photoUrl,
      'blocked': blocked,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? headline,
    String? college,
    String? photoUrl,
    bool? blocked,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      headline: headline ?? this.headline,
      college: college ?? this.college,
      photoUrl: photoUrl ?? this.photoUrl,
      blocked: blocked ?? this.blocked,
    );
  }

  @override
  List<Object?> get props => [id, name, email, headline, college, photoUrl, blocked];
}
