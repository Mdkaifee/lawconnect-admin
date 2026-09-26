import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/case_model.dart';
import '../../repositories/case_repository.dart';

// Events
abstract class CaseEvent extends Equatable {
  const CaseEvent();
  @override
  List<Object?> get props => [];
}

class SearchCasesEvent extends CaseEvent {
  final String query;
  final String? court;
  final int? year;
  final int page;
  final bool isNewSearch;

  const SearchCasesEvent({
    required this.query,
    this.court,
    this.year,
    this.page = 1,
    this.isNewSearch = true,
  });

  @override
  List<Object?> get props => [query, court, year, page, isNewSearch];
}

class LoadCuratedLandmarksEvent extends CaseEvent {}

class LoadCaseDetailsEvent extends CaseEvent {
  final String id;
  const LoadCaseDetailsEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class CaseState extends Equatable {
  const CaseState();
  @override
  List<Object?> get props => [];
}

class CaseInitial extends CaseState {}

class CaseLoading extends CaseState {}

class CaseSearchSuccess extends CaseState {
  final List<CaseModel> items;
  final int total;
  final int page;
  final String provider;
  final String query;
  final String? court;
  final int? year;
  final bool hasMore;

  const CaseSearchSuccess({
    required this.items,
    required this.total,
    required this.page,
    required this.provider,
    required this.query,
    this.court,
    this.year,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [items, total, page, provider, query, court, year, hasMore];
}

class CaseDetailsLoaded extends CaseState {
  final CaseModel caseItem;
  const CaseDetailsLoaded(this.caseItem);
  @override
  List<Object?> get props => [caseItem];
}

class CaseError extends CaseState {
  final String message;
  const CaseError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class CaseBloc extends Bloc<CaseEvent, CaseState> {
  final CaseRepository _caseRepository;

  CaseBloc({required CaseRepository caseRepository})
      : _caseRepository = caseRepository,
        super(CaseInitial()) {
    on<SearchCasesEvent>(_onSearchCases);
    on<LoadCuratedLandmarksEvent>(_onLoadCuratedLandmarks);
    on<LoadCaseDetailsEvent>(_onLoadCaseDetails);
  }

  Future<void> _onSearchCases(SearchCasesEvent event, Emitter<CaseState> emit) async {
    if (event.isNewSearch) {
      emit(CaseLoading());
    }

    try {
      final result = await _caseRepository.searchCases(
        query: event.query,
        court: event.court,
        year: event.year,
        page: event.page,
      );

      final List<CaseModel> combinedItems;
      if (!event.isNewSearch && state is CaseSearchSuccess) {
        final current = (state as CaseSearchSuccess).items;
        combinedItems = [...current, ...result.items];
      } else {
        combinedItems = result.items;
      }

      final hasMore = combinedItems.length < result.total && result.items.isNotEmpty;

      emit(CaseSearchSuccess(
        items: combinedItems,
        total: result.total,
        page: result.page,
        provider: result.provider,
        query: event.query,
        court: event.court,
        year: event.year,
        hasMore: hasMore,
      ));
    } catch (e) {
      emit(CaseError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadCuratedLandmarks(LoadCuratedLandmarksEvent event, Emitter<CaseState> emit) async {
    emit(CaseLoading());
    try {
      final items = await _caseRepository.getCuratedLandmarks();
      emit(CaseSearchSuccess(
        items: items,
        total: items.length,
        page: 1,
        provider: 'curated',
        query: '',
        hasMore: false,
      ));
    } catch (e) {
      emit(CaseError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadCaseDetails(LoadCaseDetailsEvent event, Emitter<CaseState> emit) async {
    emit(CaseLoading());
    try {
      final caseItem = await _caseRepository.getCaseDetails(event.id);
      emit(CaseDetailsLoaded(caseItem));
    } catch (e) {
      emit(CaseError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
