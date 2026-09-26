import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/update_model.dart';
import '../../repositories/update_repository.dart';

// Events
abstract class UpdateEvent extends Equatable {
  const UpdateEvent();
  @override
  List<Object?> get props => [];
}

class LoadUpdatesEvent extends UpdateEvent {
  final String? court;
  final String? category;
  final String? query;
  const LoadUpdatesEvent({this.court, this.category, this.query});
  @override
  List<Object?> get props => [court, category, query];
}

// States
abstract class UpdateState extends Equatable {
  const UpdateState();
  @override
  List<Object?> get props => [];
}

class UpdateInitial extends UpdateState {}

class UpdateLoading extends UpdateState {}

class UpdateLoaded extends UpdateState {
  final List<UpdateModel> updates;
  final String? selectedCategory;
  final String? selectedCourt;
  const UpdateLoaded(this.updates, {this.selectedCategory, this.selectedCourt});
  @override
  List<Object?> get props => [updates, selectedCategory, selectedCourt];
}

class UpdateError extends UpdateState {
  final String message;
  const UpdateError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class UpdateBloc extends Bloc<UpdateEvent, UpdateState> {
  final UpdateRepository _updateRepository;

  UpdateBloc({required UpdateRepository updateRepository})
      : _updateRepository = updateRepository,
        super(UpdateInitial()) {
    on<LoadUpdatesEvent>(_onLoadUpdates);
  }

  Future<void> _onLoadUpdates(LoadUpdatesEvent event, Emitter<UpdateState> emit) async {
    emit(UpdateLoading());
    try {
      final updates = await _updateRepository.getUpdates(
        court: event.court,
        category: event.category,
        query: event.query,
      );
      emit(UpdateLoaded(updates, selectedCategory: event.category, selectedCourt: event.court));
    } catch (e) {
      emit(UpdateError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

