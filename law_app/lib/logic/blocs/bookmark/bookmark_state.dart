import 'package:equatable/equatable.dart';
import '../../../data/models/bookmark_model.dart';

abstract class BookmarkState extends Equatable {
  const BookmarkState();
  @override
  List<Object?> get props => [];
}

class BookmarkInitial extends BookmarkState {}

class BookmarkLoading extends BookmarkState {}

class BookmarksLoaded extends BookmarkState {
  final List<BookmarkModel> bookmarks;
  final String selectedTab;

  const BookmarksLoaded({
    required this.bookmarks,
    this.selectedTab = 'Cases',
  });

  @override
  List<Object?> get props => [bookmarks, selectedTab];
}

class BookmarkError extends BookmarkState {
  final String message;
  const BookmarkError(this.message);

  @override
  List<Object?> get props => [message];
}
