import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/update_repository.dart';
import 'update_event.dart';
import 'update_state.dart';

class UpdateBloc extends Bloc<UpdateEvent, UpdateState> {
  final UpdateRepository _updateRepository;

  UpdateBloc(this._updateRepository) : super(UpdateInitial()) {
    on<FetchUpdatesEvent>(_onFetchUpdates);
  }

  Future<void> _onFetchUpdates(FetchUpdatesEvent event, Emitter<UpdateState> emit) async {
    if (!event.refresh && state is! UpdatesLoaded) {
      emit(UpdateLoading());
    }
    try {
      final updates = await _updateRepository.getLegalUpdates(court: event.court);
      emit(UpdatesLoaded(
        updates: updates,
        selectedCourt: event.court ?? 'Latest',
      ));
    } catch (e) {
      emit(UpdateError(e.toString()));
    }
  }
}
