import 'package:equatable/equatable.dart';

abstract class UpdateEvent extends Equatable {
  const UpdateEvent();
  @override
  List<Object?> get props => [];
}

class FetchUpdatesEvent extends UpdateEvent {
  final String? court;
  final bool refresh;

  const FetchUpdatesEvent({this.court, this.refresh = false});

  @override
  List<Object?> get props => [court, refresh];
}
