import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:law_app/core/constants/api_constants.dart';
import 'package:law_app/models/notification_model.dart';
import 'package:law_app/repositories/auth_repository.dart';

class NotificationRepository {
  final http.Client _client;
  final AuthRepository _authRepo;
  static const String _localReadIdsKey = 'read_notification_ids';

  NotificationRepository({required AuthRepository authRepo, http.Client? client})
      : _authRepo = authRepo,
        _client = client ?? http.Client();

  /// Default fallback sample notifications for instant display / offline fallback
  List<NotificationModel> get _defaultNotifications => [
        NotificationModel(
          id: 'welcome_system_1',
          title: 'Welcome to Rishikesh Law Hub',
          body: 'Explore landmark Supreme Court judgments, new criminal bare acts (BNS, BNSS, BSA), and daily legal updates.',
          type: 'general',
          refType: 'general',
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        NotificationModel(
          id: 'landmark_case_1',
          title: 'New Landmark Judgment Available',
          body: 'Explore Kesavananda Bharati v. State of Kerala - Basic Structure Doctrine & Constitutional bench analysis.',
          type: 'case',
          refId: 'kesavananda_bharati',
          refType: 'case',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotificationModel(
          id: 'bare_act_bns_1',
          title: 'Updated Bare Act: Bharatiya Nyaya Sanhita (BNS)',
          body: 'Access indexed sections, comparative IPC tables, and key criminal law amendments.',
          type: 'act',
          refId: 'bns_2023',
          refType: 'act',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        NotificationModel(
          id: 'daily_update_1',
          title: 'Daily Legal Pulse',
          body: 'Supreme Court establishes comprehensive guidelines on digital evidence and electronic record admissibility.',
          type: 'update',
          refId: 'digital_evidence_guidelines',
          refType: 'update',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

  Future<Set<String>> _getLocalReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_localReadIdsKey) ?? [];
    return list.toSet();
  }

  Future<void> _saveLocalReadId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_localReadIdsKey) ?? []).toSet();
    set.add(id);
    await prefs.setStringList(_localReadIdsKey, set.toList());
  }

  Future<void> _saveAllLocalReadIds(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_localReadIdsKey) ?? []).toSet();
    set.addAll(ids);
    await prefs.setStringList(_localReadIdsKey, set.toList());
  }

  /// Fetches notifications from backend or returns fallback items
  Future<List<NotificationModel>> getNotifications() async {
    final localReadIds = await _getLocalReadIds();

    try {
      final uri = Uri.parse(ApiConstants.notifications);
      final response = await _client.get(
        uri,
        headers: _authRepo.isAuthenticated ? _authRepo.authHeaders : {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final rawItems = (data['items'] as List<dynamic>?) ?? [];
        if (rawItems.isNotEmpty) {
          return rawItems.map((e) {
            final model = NotificationModel.fromJson(e as Map<String, dynamic>);
            final isLocallyRead = localReadIds.contains(model.id);
            return model.copyWith(isRead: model.isRead || isLocallyRead);
          }).toList();
        }
      }
    } catch (_) {
      // Network or parsing error: fallback to default items
    }

    // Fallback items with locally persisted read state
    return _defaultNotifications.map((notif) {
      final isLocallyRead = localReadIds.contains(notif.id);
      return notif.copyWith(isRead: notif.isRead || isLocallyRead);
    }).toList();
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String id) async {
    await _saveLocalReadId(id);

    try {
      final uri = Uri.parse('${ApiConstants.notifications}/$id/read');
      await _client.put(
        uri,
        headers: _authRepo.isAuthenticated ? _authRepo.authHeaders : {'Content-Type': 'application/json'},
      );
    } catch (_) {}
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(List<String> allIds) async {
    await _saveAllLocalReadIds(allIds);

    try {
      final uri = Uri.parse(ApiConstants.notificationsReadAll);
      await _client.post(
        uri,
        headers: _authRepo.isAuthenticated ? _authRepo.authHeaders : {'Content-Type': 'application/json'},
      );
    } catch (_) {}
  }

  /// Dismiss or delete a notification
  Future<void> deleteNotification(String id) async {
    try {
      final uri = Uri.parse('${ApiConstants.notifications}/$id');
      await _client.delete(
        uri,
        headers: _authRepo.isAuthenticated ? _authRepo.authHeaders : {'Content-Type': 'application/json'},
      );
    } catch (_) {}
  }
}
