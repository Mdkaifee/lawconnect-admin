import 'package:equatable/equatable.dart';
import '../../../data/models/legal_update_model.dart';

abstract class UpdateState extends Equatable {
  const UpdateState();
  @override
  List<Object?> get props => [];
}

class UpdateInitial extends UpdateState {}

class UpdateLoading extends UpdateState {}

class UpdatesLoaded extends UpdateState {
  final List<LegalUpdateModel> updates;
  final String selectedCourt;

  const UpdatesLoaded({
    required this.updates,
    this.selectedCourt = 'Latest',
  });

  @override
  List<Object?> get props => [updates, selectedCourt];
}

class UpdateError extends UpdateState {
  final String message;
  const UpdateError(this.message);

  @override
  List<Object?> get props => [message];
}
