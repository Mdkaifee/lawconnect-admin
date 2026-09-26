import 'package:equatable/equatable.dart';

class SectionModel extends Equatable {
  final String id;
  final String number;
  final String title;
  final String? chapter;
  final String text;
  final String? explanation;

  const SectionModel({
    required this.id,
    required this.number,
    required this.title,
    this.chapter,
    required this.text,
    this.explanation,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['sectionId']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      chapter: json['chapter']?.toString(),
      text: json['text']?.toString() ?? '',
      explanation: json['explanation']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, number, title, chapter, text, explanation];
}

class ActModel extends Equatable {
  final String id;
  final String name;
  final String shortName;
  final String? actNumber;
  final int? year;
  final String type; // 'Central' | 'State'
  final String? description;
  final String? sourceUrl;
  final List<SectionModel> sections;
  final int sectionsCount;

  const ActModel({
    required this.id,
    required this.name,
    required this.shortName,
    this.actNumber,
    this.year,
    this.type = 'Central',
    this.description,
    this.sourceUrl,
    this.sections = const [],
    this.sectionsCount = 0,
  });

  factory ActModel.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>?;
    final parsedSections = rawSections != null
        ? rawSections.map((s) => SectionModel.fromJson(s as Map<String, dynamic>)).toList()
        : <SectionModel>[];

    return ActModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Act',
      shortName: json['shortName']?.toString() ?? json['name']?.toString() ?? '',
      actNumber: json['actNumber']?.toString(),
      year: (json['year'] as num?)?.toInt(),
      type: json['type']?.toString() ?? 'Central',
      description: json['description']?.toString(),
      sourceUrl: json['sourceUrl']?.toString(),
      sections: parsedSections,
      sectionsCount: (json['sectionsCount'] as num?)?.toInt() ?? parsedSections.length,
    );
  }

  @override
  List<Object?> get props => [id, name, shortName, year, type, sections, sectionsCount];
}

