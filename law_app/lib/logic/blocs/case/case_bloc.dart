import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/case_repository.dart';
import 'case_event.dart';
import 'case_state.dart';

class CaseBloc extends Bloc<CaseEvent, CaseState> {
  final CaseRepository _caseRepository;

  CaseBloc(this._caseRepository) : super(CaseInitial()) {
    on<FetchCasesEvent>(_onFetchCases);
    on<FetchCaseDetailsEvent>(_onFetchCaseDetails);
  }

  Future<void> _onFetchCases(FetchCasesEvent event, Emitter<CaseState> emit) async {
    if (!event.refresh && state is! CasesLoaded) {
      emit(CaseLoading());
    }
    try {
      final cases = await _caseRepository.getCases(
        query: event.query,
        court: event.court,
        category: event.category,
      );
      emit(CasesLoaded(
        cases: cases,
        selectedCourt: event.court ?? 'All',
        searchQuery: event.query ?? '',
      ));
    } catch (e) {
      emit(CaseError(e.toString()));
    }
  }

  Future<void> _onFetchCaseDetails(FetchCaseDetailsEvent event, Emitter<CaseState> emit) async {
    emit(CaseLoading());
    try {
      final caseModel = await _caseRepository.getCaseDetails(event.id);
      await _caseRepository.recordReadingHistory(caseModel.id, caseModel.title);
      emit(CaseDetailLoaded(caseModel));
    } catch (e) {
      emit(CaseError(e.toString()));
    }
  }
}
