import 'package:equatable/equatable.dart';

class CaseReference extends Equatable {
  final String providerId;
  final String title;
  final String relationship; // 'cites' or 'citedby'
  final String? sourceUrl;

  const CaseReference({
    required this.providerId,
    required this.title,
    required this.relationship,
    this.sourceUrl,
  });

  factory CaseReference.fromJson(Map<String, dynamic> json) {
    return CaseReference(
      providerId: json['providerId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Case',
      relationship: json['relationship']?.toString() ?? 'cites',
      sourceUrl: json['sourceUrl']?.toString(),
    );
  }

  @override
  List<Object?> get props => [providerId, title, relationship, sourceUrl];
}

class CaseModel extends Equatable {
  final String id;
  final String providerId;
  final String provider; // 'curated' | 'indian_kanoon' | 'hybrid'
  final String title;
  final String? citation;
  final String court;
  final String courtType;
  final String? bench;
  final String? petitioners;
  final String? respondents;
  final String? dateOfJudgment;
  final String? summary;
  final String? simpleExplanation;
  final String? fullText;
  final List<String> tags;
  final List<CaseReference> cites;
  final List<CaseReference> citedBy;
  final bool hasCourtCopy;
  final String? origDocUrl;
  final String? sourceUrl;
  final bool isCurated;
  final bool isFeatured;

  const CaseModel({
    required this.id,
    required this.providerId,
    this.provider = 'curated',
    required this.title,
    this.citation,
    required this.court,
    this.courtType = 'Supreme Court',
    this.bench,
    this.petitioners,
    this.respondents,
    this.dateOfJudgment,
    this.summary,
    this.simpleExplanation,
    this.fullText,
    this.tags = const [],
    this.cites = const [],
    this.citedBy = const [],
    this.hasCourtCopy = false,
    this.origDocUrl,
    this.sourceUrl,
    this.isCurated = false,
    this.isFeatured = false,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    final citesList = (json['cites'] as List<dynamic>?)
            ?.map((e) => CaseReference.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final citedByList = (json['citedBy'] as List<dynamic>?)
            ?.map((e) => CaseReference.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final tagsList = (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return CaseModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? json['id']?.toString() ?? json['_id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'curated',
      title: json['title']?.toString() ?? 'Untitled Judgment',
      citation: json['citation']?.toString(),
      court: json['court']?.toString() ?? 'Supreme Court of India',
      courtType: json['courtType']?.toString() ?? 'Supreme Court',
      bench: json['bench']?.toString(),
      petitioners: json['petitioners']?.toString(),
      respondents: json['respondents']?.toString(),
      dateOfJudgment: json['dateOfJudgment']?.toString(),
      summary: json['summary']?.toString() ?? json['snippet']?.toString(),
      simpleExplanation: json['simpleExplanation']?.toString(),
      fullText: json['fullText']?.toString(),
      tags: tagsList,
      cites: citesList,
      citedBy: citedByList,
      hasCourtCopy: json['hasCourtCopy'] == true,
      origDocUrl: json['origDocUrl']?.toString(),
      sourceUrl: json['sourceUrl']?.toString() ?? json['judgmentPdfUrl']?.toString(),
      isCurated: json['isCurated'] == true,
      isFeatured: json['isFeatured'] == true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        providerId,
        provider,
        title,
        citation,
        court,
        courtType,
        bench,
        dateOfJudgment,
        summary,
        simpleExplanation,
        fullText,
        tags,
        cites,
        citedBy,
        hasCourtCopy,
        isCurated,
        isFeatured,
      ];
}

