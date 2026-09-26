import 'package:equatable/equatable.dart';

abstract class CaseEvent extends Equatable {
  const CaseEvent();
  @override
  List<Object?> get props => [];
}

class FetchCasesEvent extends CaseEvent {
  final String? query;
  final String? court;
  final String? category;
  final bool refresh;

  const FetchCasesEvent({
    this.query,
    this.court,
    this.category,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [query, court, category, refresh];
}

class FetchCaseDetailsEvent extends CaseEvent {
  final String id;
  const FetchCaseDetailsEvent(this.id);

  @override
  List<Object?> get props => [id];
}
