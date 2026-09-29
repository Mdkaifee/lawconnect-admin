class ApiConstants {
  // Default base URL pointing to the live Render backend or local dev
  static const String baseUrl = 'https://lawconnect-admin.onrender.com/api';
  
  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String changePassword = '$baseUrl/auth/change-password';
  static const String register = '$baseUrl/auth/register';
  static const String me = '$baseUrl/auth/me';
  static const String follow = '$baseUrl/auth/follow';
  static const String following = '$baseUrl/auth/following';
  static const String deleteAccount = '$baseUrl/auth/delete-account';
  static const String fcmToken = '$baseUrl/auth/fcm-token';
  static const String fcmTokenRemove = '$baseUrl/auth/fcm-token/remove';
  static const String privacyPolicyUrl = 'https://rishikesh-law-hub-admin.onrender.com/privacy-policy';
  static const String termsOfServiceUrl = 'https://rishikesh-law-hub-admin.onrender.com/terms-of-service';
  static const String deleteAccountUrl = 'https://rishikesh-law-hub-admin.onrender.com/delete-account';

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
  static const String appUsers = '$baseUrl/users/app/list';

  // Personal user data
  static const String notes = '$baseUrl/notes';
  static const String bookmarks = '$baseUrl/bookmarks';
  static const String history = '$baseUrl/history';
  static const String categories = '$baseUrl/categories';

  // Notifications endpoints
  static const String notifications = '$baseUrl/notifications';
  static const String notificationsReadAll = '$baseUrl/notifications/read-all';
  static const String messages = '$baseUrl/messages';
  static const String aiChat = '$baseUrl/ai/chat';
}
