import 'package:equatable/equatable.dart';

class CaseModel extends Equatable {
  final String id;
  final String title;
  final String citation;
  final int year;
  final String court;
  final String courtType;
  final String bench;
  final String petitioners;
  final String respondents;
  final String? dateOfJudgment;
  final List<String> tags;
  final List<String> categories;
  final String summary;
  final String simpleExplanation;
  final String judgmentPdfUrl;
  final bool isBookmarked;

  const CaseModel({
    required this.id,
    required this.title,
    this.citation = '',
    this.year = 2024,
    this.court = 'Supreme Court of India',
    this.courtType = 'Supreme Court',
    this.bench = '',
    this.petitioners = '',
    this.respondents = '',
    this.dateOfJudgment,
    this.tags = const [],
    this.categories = const [],
    this.summary = '',
    this.simpleExplanation = '',
    this.judgmentPdfUrl = '',
    this.isBookmarked = false,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      citation: json['citation']?.toString() ?? '',
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? '') ?? 2024,
      court: json['court']?.toString() ?? 'Supreme Court of India',
      courtType: json['courtType']?.toString() ?? 'Supreme Court',
      bench: json['bench']?.toString() ?? '',
      petitioners: json['petitioners']?.toString() ?? '',
      respondents: json['respondents']?.toString() ?? '',
      dateOfJudgment: json['dateOfJudgment']?.toString(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      categories: (json['categories'] as List?)?.map((e) => e.toString()).toList() ?? [],
      summary: json['summary']?.toString() ?? '',
      simpleExplanation: json['simpleExplanation']?.toString() ?? '',
      judgmentPdfUrl: json['judgmentPdfUrl']?.toString() ?? '',
      isBookmarked: json['isBookmarked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'title': title,
      'citation': citation,
      'year': year,
      'court': court,
      'courtType': courtType,
      'bench': bench,
      'petitioners': petitioners,
      'respondents': respondents,
      'dateOfJudgment': dateOfJudgment,
      'tags': tags,
      'categories': categories,
      'summary': summary,
      'simpleExplanation': simpleExplanation,
      'judgmentPdfUrl': judgmentPdfUrl,
    };
  }

  CaseModel copyWith({
    bool? isBookmarked,
  }) {
    return CaseModel(
      id: id,
      title: title,
      citation: citation,
      year: year,
      court: court,
      courtType: courtType,
      bench: bench,
      petitioners: petitioners,
      respondents: respondents,
      dateOfJudgment: dateOfJudgment,
      tags: tags,
      categories: categories,
      summary: summary,
      simpleExplanation: simpleExplanation,
      judgmentPdfUrl: judgmentPdfUrl,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        citation,
        year,
        court,
        courtType,
        bench,
        petitioners,
        respondents,
        dateOfJudgment,
        tags,
        categories,
        summary,
        simpleExplanation,
        judgmentPdfUrl,
        isBookmarked,
      ];
}
