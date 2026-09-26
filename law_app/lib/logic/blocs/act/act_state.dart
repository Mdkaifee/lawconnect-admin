import 'package:equatable/equatable.dart';
import '../../../data/models/act_model.dart';

abstract class ActState extends Equatable {
  const ActState();
  @override
  List<Object?> get props => [];
}

class ActInitial extends ActState {}

class ActLoading extends ActState {}

class ActsLoaded extends ActState {
  final List<ActModel> acts;
  final String selectedType;
  final List<SectionModel> searchResults;

  const ActsLoaded({
    required this.acts,
    this.selectedType = 'All Acts',
    this.searchResults = const [],
  });

  @override
  List<Object?> get props => [acts, selectedType, searchResults];
}

class ActDetailLoaded extends ActState {
  final ActModel act;
  const ActDetailLoaded(this.act);

  @override
  List<Object?> get props => [act];
}

class ActError extends ActState {
  final String message;
  const ActError(this.message);

  @override
  List<Object?> get props => [message];
}
