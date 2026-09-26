import 'package:equatable/equatable.dart';
import '../../../data/models/case_model.dart';

abstract class CaseState extends Equatable {
  const CaseState();
  @override
  List<Object?> get props => [];
}

class CaseInitial extends CaseState {}

class CaseLoading extends CaseState {}

class CasesLoaded extends CaseState {
  final List<CaseModel> cases;
  final String selectedCourt;
  final String searchQuery;

  const CasesLoaded({
    required this.cases,
    this.selectedCourt = 'All',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [cases, selectedCourt, searchQuery];
}

class CaseDetailLoaded extends CaseState {
  final CaseModel caseModel;
  const CaseDetailLoaded(this.caseModel);

  @override
  List<Object?> get props => [caseModel];
}

class CaseError extends CaseState {
  final String message;
  const CaseError(this.message);

  @override
  List<Object?> get props => [message];
}
