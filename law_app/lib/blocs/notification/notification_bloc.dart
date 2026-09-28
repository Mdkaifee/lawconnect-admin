import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';

/* ---------------- EVENTS ---------------- */

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationEvent {
  final bool isRefresh;
  const LoadNotificationsEvent({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class MarkNotificationAsReadEvent extends NotificationEvent {
  final String id;
  const MarkNotificationAsReadEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsAsReadEvent extends NotificationEvent {
  const MarkAllNotificationsAsReadEvent();
}

class DeleteNotificationEvent extends NotificationEvent {
  final String id;
  const DeleteNotificationEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/* ---------------- STATES ---------------- */

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isRefreshing;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [notifications, unreadCount, isRefreshing];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

/* ---------------- BLOC ---------------- */

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationBloc({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository,
        super(NotificationInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllNotificationsAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (!event.isRefresh && state is! NotificationLoaded) {
      emit(NotificationLoading());
    } else if (state is NotificationLoaded) {
      final current = state as NotificationLoaded;
      emit(NotificationLoaded(
        notifications: current.notifications,
        unreadCount: current.unreadCount,
        isRefreshing: true,
      ));
    }

    try {
      final items = await _notificationRepository.getNotifications();
      final unread = items.where((item) => !item.isRead).length;
      emit(NotificationLoaded(notifications: items, unreadCount: unread, isRefreshing: false));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final current = state as NotificationLoaded;
      final updated = current.notifications.map((item) {
        if (item.id == event.id) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();
      final unread = updated.where((item) => !item.isRead).length;
      emit(NotificationLoaded(notifications: updated, unreadCount: unread));

      await _notificationRepository.markAsRead(event.id);
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final current = state as NotificationLoaded;
      final updated = current.notifications.map((item) => item.copyWith(isRead: true)).toList();
      emit(NotificationLoaded(notifications: updated, unreadCount: 0));

      final allIds = current.notifications.map((e) => e.id).toList();
      await _notificationRepository.markAllAsRead(allIds);
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final current = state as NotificationLoaded;
      final updated = current.notifications.where((item) => item.id != event.id).toList();
      final unread = updated.where((item) => !item.isRead).length;
      emit(NotificationLoaded(notifications: updated, unreadCount: unread));

      await _notificationRepository.deleteNotification(event.id);
    }
  }
}
