import 'package:equatable/equatable.dart';

class SectionModel extends Equatable {
  final String id;
  final String number;
  final String title;
  final String text;
  final String explanation;

  const SectionModel({
    required this.id,
    required this.number,
    this.title = '',
    this.text = '',
    this.explanation = '',
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['sectionId']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'number': number,
      'title': title,
      'text': text,
      'explanation': explanation,
    };
  }

  @override
  List<Object?> get props => [id, number, title, text, explanation];
}

class ActModel extends Equatable {
  final String id;
  final String name;
  final String shortName;
  final int year;
  final String type; // Central / State
  final String description;
  final List<SectionModel> sections;

  const ActModel({
    required this.id,
    required this.name,
    this.shortName = '',
    this.year = 1950,
    this.type = 'Central',
    this.description = '',
    this.sections = const [],
  });

  factory ActModel.fromJson(Map<String, dynamic> json) {
    return ActModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: json['shortName']?.toString() ?? '',
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? '') ?? 1950,
      type: json['type']?.toString() ?? 'Central',
      description: json['description']?.toString() ?? '',
      sections: (json['sections'] as List?)
              ?.map((s) => SectionModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'shortName': shortName,
      'year': year,
      'type': type,
      'description': description,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, name, shortName, year, type, description, sections];
}
