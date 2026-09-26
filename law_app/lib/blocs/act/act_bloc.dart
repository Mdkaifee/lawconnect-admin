import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/act_model.dart';
import '../../repositories/act_repository.dart';

// Events
abstract class ActEvent extends Equatable {
  const ActEvent();
  @override
  List<Object?> get props => [];
}

class LoadActsEvent extends ActEvent {
  final String? query;
  final String? type;
  final int page;
  final bool isNewLoad;
  const LoadActsEvent({this.query, this.type, this.page = 1, this.isNewLoad = true});
  @override
  List<Object?> get props => [query, type, page, isNewLoad];
}

class LoadActDetailsEvent extends ActEvent {
  final String id;
  const LoadActDetailsEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class ActState extends Equatable {
  const ActState();
  @override
  List<Object?> get props => [];
}

class ActInitial extends ActState {}

class ActLoading extends ActState {}

class ActListLoaded extends ActState {
  final List<ActModel> acts;
  final String? filterType;
  final String? query;
  final int page;
  final int total;
  final bool hasMore;
  const ActListLoaded(
    this.acts, {
    this.filterType,
    this.query,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  @override
  List<Object?> get props => [acts, filterType, query, page, total, hasMore];
}

class ActDetailsLoaded extends ActState {
  final ActModel act;
  const ActDetailsLoaded(this.act);
  @override
  List<Object?> get props => [act];
}

class ActError extends ActState {
  final String message;
  const ActError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ActBloc extends Bloc<ActEvent, ActState> {
  final ActRepository _actRepository;

  ActBloc({required ActRepository actRepository})
      : _actRepository = actRepository,
        super(ActInitial()) {
    on<LoadActsEvent>(_onLoadActs);
    on<LoadActDetailsEvent>(_onLoadActDetails);
  }

  Future<void> _onLoadActs(LoadActsEvent event, Emitter<ActState> emit) async {
    if (event.isNewLoad) emit(ActLoading());
    try {
      final result = await _actRepository.getActs(query: event.query, type: event.type, page: event.page);
      final combinedActs = !event.isNewLoad && state is ActListLoaded
          ? [...(state as ActListLoaded).acts, ...result.items]
          : result.items;
      emit(ActListLoaded(
        combinedActs,
        filterType: event.type,
        query: event.query,
        page: result.page,
        total: result.total,
        hasMore: combinedActs.length < result.total && result.items.isNotEmpty,
      ));
    } catch (e) {
      emit(ActError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadActDetails(LoadActDetailsEvent event, Emitter<ActState> emit) async {
    emit(ActLoading());
    try {
      final act = await _actRepository.getActDetails(event.id);
      emit(ActDetailsLoaded(act));
    } catch (e) {
      emit(ActError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

