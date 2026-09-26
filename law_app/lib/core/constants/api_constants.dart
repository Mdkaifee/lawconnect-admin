class ApiConstants {
  // Default base URL pointing to the live Render backend or local dev
  static const String baseUrl = 'https://lawconnect-admin.onrender.com/api';
  
  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String me = '$baseUrl/auth/me';
  static const String follow = '$baseUrl/auth/follow';
  static const String following = '$baseUrl/auth/following';

  // Cases endpoints
  static const String cases = '$baseUrl/cases';
  static const String caseSearch = '$baseUrl/cases/search';
  static const String caseDoc = '$baseUrl/cases/doc';

  // Acts endpoints
  static const String acts = '$baseUrl/acts';
  static const String actSectionSearch = '$baseUrl/acts/search/sections';

  // Updates endpoints
  static const String updates = '$baseUrl/updates';

  // Posts & Social endpoints
  static const String posts = '$baseUrl/posts';
  static const String users = '$baseUrl/users';

  // Personal user data
  static const String notes = '$baseUrl/notes';
  static const String bookmarks = '$baseUrl/bookmarks';
  static const String history = '$baseUrl/history';
  static const String categories = '$baseUrl/categories';
}
