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
  final int page;
  final bool isNewLoad;
  const LoadUpdatesEvent({this.court, this.category, this.query, this.page = 1, this.isNewLoad = true});
  @override
  List<Object?> get props => [court, category, query, page, isNewLoad];
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
  final int page;
  final int total;
  final bool hasMore;
  const UpdateLoaded(
    this.updates, {
    this.selectedCategory,
    this.selectedCourt,
    required this.page,
    required this.total,
    required this.hasMore,
  });
  @override
  List<Object?> get props => [updates, selectedCategory, selectedCourt, page, total, hasMore];
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
    if (event.isNewLoad) emit(UpdateLoading());
    try {
      final result = await _updateRepository.getUpdates(
        court: event.court,
        category: event.category,
        query: event.query,
        page: event.page,
      );
      final combinedUpdates = !event.isNewLoad && state is UpdateLoaded
          ? [...(state as UpdateLoaded).updates, ...result.items]
          : result.items;
      emit(UpdateLoaded(
        combinedUpdates,
        selectedCategory: event.category,
        selectedCourt: event.court,
        page: result.page,
        total: result.total,
        hasMore: combinedUpdates.length < result.total && result.items.isNotEmpty,
      ));
    } catch (e) {
      emit(UpdateError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

