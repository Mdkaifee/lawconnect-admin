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
  const LoadActsEvent({this.query, this.type});
  @override
  List<Object?> get props => [query, type];
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
  const ActListLoaded(this.acts, {this.filterType});
  @override
  List<Object?> get props => [acts, filterType];
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
    emit(ActLoading());
    try {
      final acts = await _actRepository.getActs(query: event.query, type: event.type);
      emit(ActListLoaded(acts, filterType: event.type));
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

