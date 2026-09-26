import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/act_repository.dart';
import 'act_event.dart';
import 'act_state.dart';

class ActBloc extends Bloc<ActEvent, ActState> {
  final ActRepository _actRepository;

  ActBloc(this._actRepository) : super(ActInitial()) {
    on<FetchActsEvent>(_onFetchActs);
    on<FetchActDetailsEvent>(_onFetchActDetails);
    on<SearchSectionsEvent>(_onSearchSections);
  }

  Future<void> _onFetchActs(FetchActsEvent event, Emitter<ActState> emit) async {
    emit(ActLoading());
    try {
      final acts = await _actRepository.getActs(
        query: event.query,
        type: event.type,
      );
      emit(ActsLoaded(
        acts: acts,
        selectedType: event.type ?? 'All Acts',
      ));
    } catch (e) {
      emit(ActError(e.toString()));
    }
  }

  Future<void> _onFetchActDetails(FetchActDetailsEvent event, Emitter<ActState> emit) async {
    emit(ActLoading());
    try {
      final act = await _actRepository.getActDetails(event.id);
      emit(ActDetailLoaded(act));
    } catch (e) {
      emit(ActError(e.toString()));
    }
  }

  Future<void> _onSearchSections(SearchSectionsEvent event, Emitter<ActState> emit) async {
    emit(ActLoading());
    try {
      final results = await _actRepository.searchSections(event.query);
      emit(ActsLoaded(acts: const [], searchResults: results));
    } catch (e) {
      emit(ActError(e.toString()));
    }
  }
}
