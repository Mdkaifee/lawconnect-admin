import 'package:equatable/equatable.dart';

abstract class ActEvent extends Equatable {
  const ActEvent();
  @override
  List<Object?> get props => [];
}

class FetchActsEvent extends ActEvent {
  final String? query;
  final String? type;

  const FetchActsEvent({this.query, this.type});

  @override
  List<Object?> get props => [query, type];
}

class FetchActDetailsEvent extends ActEvent {
  final String id;
  const FetchActDetailsEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SearchSectionsEvent extends ActEvent {
  final String query;
  const SearchSectionsEvent(this.query);

  @override
  List<Object?> get props => [query];
}
