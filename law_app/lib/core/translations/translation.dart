import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('English', 'en'),
  hindi('Hindi', 'hi');

  final String label;
  final String code;

  const AppLanguage(this.label, this.code);
}

class Translation extends ChangeNotifier {
  Translation._();

  static final Translation instance = Translation._();
  static const String _languageKey = 'app_language';

  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;
  String get currentLanguageLabel => _language.label;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);
    _language = AppLanguage.values.firstWhere(
      (language) => language.code == savedCode,
      orElse: () => AppLanguage.english,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
    notifyListeners();
  }

  static String t(String key) {
    final lang = instance.language.code;
    return _translations[key]?[lang] ?? _translations[key]?['en'] ?? key;
  }
}

const Map<String, Map<String, String>> _translations = {
  'home': {'en': 'Home', 'hi': 'होम'},
  'search': {'en': 'Search', 'hi': 'खोजें'},
  'posts': {'en': 'Posts', 'hi': 'पोस्ट'},
  'bookmarks': {'en': 'Bookmarks', 'hi': 'बुकमार्क'},
  'profile': {'en': 'Profile', 'hi': 'प्रोफाइल'},
  'edit_profile': {'en': 'Edit Profile', 'hi': 'प्रोफाइल संपादित करें'},
  'settings': {'en': 'Settings', 'hi': 'सेटिंग्स'},
  'language': {'en': 'Language', 'hi': 'भाषा'},
  'select_language': {'en': 'Select Language', 'hi': 'भाषा चुनें'},
  'all_categories': {'en': 'All Legal Categories', 'hi': 'सभी कानूनी श्रेणियां'},
  'notifications': {'en': 'Notifications', 'hi': 'सूचनाएं'},
  'confirm_sign_out': {'en': 'Confirm Sign Out', 'hi': 'साइन आउट की पुष्टि करें'},
  'confirm_sign_out_msg': {'en': 'Are you sure you want to log out of Rishikesh Law Hub?', 'hi': 'क्या आप ऋषिकेश लॉ हब से लॉग आउट करना चाहते हैं?'},
  'confirm_sign_out_message': {'en': 'Are you sure you want to log out of Rishikesh Law Hub?', 'hi': 'क्या आप ऋषिकेश लॉ हब से लॉग आउट करना चाहते हैं?'},
  'cancel': {'en': 'Cancel', 'hi': 'रद्द करें'},
  'delete': {'en': 'Delete', 'hi': 'हटाएं'},
  'close': {'en': 'Close', 'hi': 'बंद करें'},
  'view_details': {'en': 'View Details', 'hi': 'विवरण देखें'},
  'view_all': {'en': 'View All', 'hi': 'सभी देखें'},
  'retry': {'en': 'Retry', 'hi': 'फिर कोशिश करें'},
  'not_added': {'en': 'Not added', 'hi': 'जोड़ा नहीं गया'},
  'email': {'en': 'Email', 'hi': 'ईमेल'},
  'followers': {'en': 'Followers', 'hi': 'फॉलोअर्स'},
  'following': {'en': 'Following', 'hi': 'फॉलोइंग'},
  'profile_load_failed': {'en': 'Failed to load profile.', 'hi': 'प्रोफाइल लोड नहीं हो सकी।'},
  'no_posts_found': {'en': 'No posts found.', 'hi': 'कोई पोस्ट नहीं मिली।'},
  'delete_account_title': {'en': 'Delete Account?', 'hi': 'अकाउंट हटाएं?'},
  'delete_account_confirm_message': {
    'en': 'Your account will be scheduled for deletion. If you do not log in again within 7 days, your account and all associated data will be permanently deleted.',
    'hi': 'आपका अकाउंट हटाने के लिए शेड्यूल किया जाएगा। अगर आप 7 दिनों में फिर लॉग इन नहीं करते हैं, तो अकाउंट और उससे जुड़ा डेटा स्थायी रूप से हट जाएगा।',
  },
  'english_default': {'en': 'English (Default)', 'hi': 'अंग्रेजी (डिफॉल्ट)'},
  'hindi': {'en': 'Hindi (हिन्दी)', 'hi': 'हिन्दी'},
  'preferences': {'en': 'PREFERENCES', 'hi': 'प्राथमिकताएं'},
  'push_notifications': {'en': 'Push Notifications', 'hi': 'पुश सूचनाएं'},
  'push_notifications_subtitle': {'en': 'Daily legal updates & new judgments', 'hi': 'दैनिक कानूनी अपडेट और नए फैसले'},
  'notifications_enabled': {'en': 'Push notifications enabled', 'hi': 'पुश सूचनाएं चालू हैं'},
  'notifications_disabled': {'en': 'Push notifications disabled', 'hi': 'पुश सूचनाएं बंद हैं'},
  'dark_mode': {'en': 'Dark Mode', 'hi': 'डार्क मोड'},
  'dark_mode_subtitle': {'en': 'Easier reading for long legal briefs', 'hi': 'लंबे कानूनी नोट्स पढ़ना आसान'},
  'storage_data': {'en': 'STORAGE & DATA', 'hi': 'स्टोरेज और डेटा'},
  'clear_cached_judgments': {'en': 'Clear Cached Judgments', 'hi': 'कैश किए गए फैसले साफ करें'},
  'clear_cached_judgments_subtitle': {'en': 'Free up local device storage (4.2 MB)', 'hi': 'डिवाइस स्टोरेज खाली करें (4.2 MB)'},
  'cache_cleared': {'en': 'Offline judgment cache cleared successfully', 'hi': 'ऑफलाइन फैसलों का कैश साफ हो गया'},
  'account_management': {'en': 'ACCOUNT MANAGEMENT', 'hi': 'अकाउंट प्रबंधन'},
  'delete_account': {'en': 'Delete Account', 'hi': 'अकाउंट हटाएं'},
  'delete_account_subtitle': {'en': 'Permanently delete after 7 days if you do not log back in', 'hi': '7 दिन में लॉग इन न करने पर स्थायी रूप से हट जाएगा'},
  'about_legal': {'en': 'ABOUT & LEGAL', 'hi': 'ऐप और कानूनी जानकारी'},
  'app_version': {'en': 'App Version', 'hi': 'ऐप वर्जन'},
  'privacy_policy': {'en': 'Privacy Policy', 'hi': 'गोपनीयता नीति'},
  'terms_of_service': {'en': 'Terms of Service', 'hi': 'सेवा की शर्तें'},
  'quick_search_hint': {'en': 'Search case name, citation, or keywords...', 'hi': 'केस का नाम, उद्धरण या कीवर्ड खोजें...'},
  'key_bare_acts': {'en': 'Key Bare Acts', 'hi': 'मुख्य बेयर एक्ट्स'},
  'landmark_judgments': {'en': 'Landmark Judgments', 'hi': 'महत्वपूर्ण फैसले'},
  'verified_legal_updates': {'en': 'Verified Legal Updates', 'hi': 'सत्यापित कानूनी अपडेट'},
  'good_morning': {'en': 'Good Morning,', 'hi': 'सुप्रभात,'},
  'good_afternoon': {'en': 'Good Afternoon,', 'hi': 'शुभ दोपहर,'},
  'good_evening': {'en': 'Good Evening,', 'hi': 'शुभ संध्या,'},
  'good_night': {'en': 'Good Night,', 'hi': 'शुभ रात्रि,'},
  'learn_explore_grow': {'en': 'Learn • Explore • Grow', 'hi': 'सीखें • खोजें • आगे बढ़ें'},
  'my_posts': {'en': 'My Posts', 'hi': 'मेरी पोस्ट'},
  'my_notes': {'en': 'My Notes', 'hi': 'मेरे नोट्स'},
  'reading_history': {'en': 'Reading History', 'hi': 'रीडिंग हिस्ट्री'},
  'help_support': {'en': 'Help & Support', 'hi': 'मदद और सहायता'},
  'about_us': {'en': 'About Us', 'hi': 'हमारे बारे में'},
  'users': {'en': 'Users', 'hi': 'यूजर्स'},
  'saved_bookmarks': {'en': 'Saved Bookmarks', 'hi': 'सेव किए गए बुकमार्क'},
  'no_bookmarks': {'en': 'No bookmarks saved yet.', 'hi': 'अभी तक कोई बुकमार्क सेव नहीं है।'},
  'log_out': {'en': 'Log Out', 'hi': 'लॉग आउट'},
  'update_profile_photo': {'en': 'Update Profile Photo', 'hi': 'प्रोफाइल फोटो बदलें'},
  'take_photo': {'en': 'Take Photo', 'hi': 'फोटो लें'},
  'choose_from_gallery': {'en': 'Choose from Gallery', 'hi': 'गैलरी से चुनें'},
  'tap_photo_to_change': {'en': 'Tap photo to change', 'hi': 'बदलने के लिए फोटो पर टैप करें'},
  'name': {'en': 'Name', 'hi': 'नाम'},
  'headline': {'en': 'Headline', 'hi': 'हेडलाइन'},
  'college_org': {'en': 'College / Organization', 'hi': 'कॉलेज / संस्था'},
  'save_profile': {'en': 'Save Profile', 'hi': 'प्रोफाइल सेव करें'},
  'name_required': {'en': 'Name is required', 'hi': 'नाम जरूरी है'},
  'profile_updated': {'en': 'Profile updated successfully', 'hi': 'प्रोफाइल सफलतापूर्वक अपडेट हो गई'},
  'tap_to_explore': {'en': 'Tap to explore', 'hi': 'देखने के लिए टैप करें'},
  'no_notifications': {'en': 'No notifications yet', 'hi': 'अभी कोई सूचना नहीं है'},
  'no_notifications_subtitle': {'en': 'You are all caught up with latest legal alerts & updates', 'hi': 'आप सभी नवीनतम कानूनी अलर्ट और अपडेट से अवगत हैं'},
  'mark_all_as_read': {'en': 'Mark all as read', 'hi': 'सभी को पढ़ा हुआ करें'},
  'all_notifications': {'en': 'All', 'hi': 'सभी'},
  'unread_notifications': {'en': 'Unread', 'hi': 'अपठित'},
  'notification_dismissed': {'en': 'Notification dismissed', 'hi': 'सूचना हटा दी गई'},
  'legal_announcement': {'en': 'Legal Announcement', 'hi': 'कानूनी घोषणा'},
};
