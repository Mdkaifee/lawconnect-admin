import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/note_model.dart';
import '../models/bookmark_model.dart';
import 'auth_repository.dart';

class UserDataRepository {
  final http.Client _client;
  final AuthRepository _authRepo;

  UserDataRepository({required AuthRepository authRepo, http.Client? client})
      : _authRepo = authRepo,
        _client = client ?? http.Client();

  /* ---------------- Notes ---------------- */
  Future<List<NoteModel>> getNotes({String? refType}) async {
    if (!_authRepo.isAuthenticated) return [];
    final uri = Uri.parse(ApiConstants.notes).replace(queryParameters: {
      if (refType != null) 'refType': refType,
    });
    final response = await _client.get(uri, headers: _authRepo.authHeaders);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      return rawItems.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<NoteModel> saveNote({
    String? id,
    required String title,
    required String content,
    String refType = 'general',
    String? refId,
    String? refTitle,
  }) async {
    final payload = {
      'title': title,
      'content': content,
      'refType': refType,
      'refId': refId,
      'refTitle': refTitle,
    };

    final http.Response response;
    if (id != null && id.isNotEmpty) {
      response = await _client.put(
        Uri.parse('${ApiConstants.notes}/$id'),
        headers: _authRepo.authHeaders,
        body: jsonEncode(payload),
      );
    } else {
      response = await _client.post(
        Uri.parse(ApiConstants.notes),
        headers: _authRepo.authHeaders,
        body: jsonEncode(payload),
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return NoteModel.fromJson(data['item'] as Map<String, dynamic>);
    } else {
      throw Exception('Failed to save note');
    }
  }

  Future<void> deleteNote(String id) async {
    final response = await _client.delete(Uri.parse('${ApiConstants.notes}/$id'), headers: _authRepo.authHeaders);
    if (response.statusCode >= 300) {
      throw Exception('Failed to delete note');
    }
  }

  /* ---------------- Bookmarks ---------------- */
  Future<List<BookmarkModel>> getBookmarks({String? refType}) async {
    if (!_authRepo.isAuthenticated) return [];
    final uri = Uri.parse(ApiConstants.bookmarks).replace(queryParameters: {
      if (refType != null) 'refType': refType,
    });
    final response = await _client.get(uri, headers: _authRepo.authHeaders);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final rawItems = (data['items'] as List<dynamic>?) ?? [];
      return rawItems.map((e) => BookmarkModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> addBookmark({
    required String refType,
    required String refId,
    required String title,
    String? subtitle,
  }) async {
    await _client.post(
      Uri.parse(ApiConstants.bookmarks),
      headers: _authRepo.authHeaders,
      body: jsonEncode({
        'refType': refType,
        'refId': refId,
        'title': title,
        'subtitle': subtitle,
      }),
    );
  }

  Future<void> removeBookmark(String refIdOrBookmarkId) async {
    await _client.delete(
      Uri.parse('${ApiConstants.bookmarks}/$refIdOrBookmarkId'),
      headers: _authRepo.authHeaders,
    );
  }

  /* ---------------- History ---------------- */
  Future<List<Map<String, dynamic>>> getHistory() async {
    if (!_authRepo.isAuthenticated) return [];
    final response = await _client.get(Uri.parse(ApiConstants.history), headers: _authRepo.authHeaders);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return ((data['items'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> logHistory({required String refType, required String refId, required String title}) async {
    if (!_authRepo.isAuthenticated) return;
    try {
      await _client.post(
        Uri.parse(ApiConstants.history),
        headers: _authRepo.authHeaders,
        body: jsonEncode({'refType': refType, 'refId': refId, 'title': title}),
      );
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    if (!_authRepo.isAuthenticated) return;
    await _client.delete(Uri.parse(ApiConstants.history), headers: _authRepo.authHeaders);
  }
}

