class ApiConstants {
  static const String baseUrl = 'https://lawconnect-admin.onrender.com';
  static const String defaultApiUrl = baseUrl;

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String me = '/api/auth/me';

  // Cases
  static const String cases = '/api/cases';

  // Acts
  static const String acts = '/api/acts';
  static const String searchSections = '/api/acts/search/sections';

  // Updates
  static const String updates = '/api/updates';

  // Posts
  static const String posts = '/api/posts';
  static String likePost(String id) => '/api/posts/$id/like';

  // Notes & Bookmarks & History
  static const String notes = '/api/notes';
  static const String bookmarks = '/api/bookmarks';
  static const String history = '/api/history';
  static const String categories = '/api/categories';
}
