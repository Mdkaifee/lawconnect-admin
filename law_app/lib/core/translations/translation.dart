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
  'search': {'en': 'Search', 'hi': 'खोज'},
  'posts': {'en': 'Posts', 'hi': 'पोस्ट'},
  'bookmarks': {'en': 'Bookmarks', 'hi': 'बुकमार्क'},
  'profile': {'en': 'Profile', 'hi': 'प्रोफाइल'},
  'settings': {'en': 'Settings', 'hi': 'सेटिंग्स'},
  'language': {'en': 'Language', 'hi': 'भाषा'},
  'select_language': {'en': 'Select Language', 'hi': 'भाषा चुनें'},
  'english_default': {'en': 'English (Default)', 'hi': 'अंग्रेज़ी (डिफॉल्ट)'},
  'hindi': {'en': 'Hindi (हिंदी)', 'hi': 'हिंदी'},
  'preferences': {'en': 'PREFERENCES', 'hi': 'प्राथमिकताएं'},
  'push_notifications': {'en': 'Push Notifications', 'hi': 'पुश नोटिफिकेशन'},
  'push_notifications_subtitle': {
    'en': 'Daily legal updates & new judgments',
    'hi': 'रोज़ कानूनी अपडेट और नए फैसले',
  },
  'notifications_enabled': {'en': 'Push notifications enabled', 'hi': 'पुश नोटिफिकेशन चालू हैं'},
  'notifications_disabled': {'en': 'Push notifications disabled', 'hi': 'पुश नोटिफिकेशन बंद हैं'},
  'dark_mode': {'en': 'Dark Mode', 'hi': 'डार्क मोड'},
  'dark_mode_subtitle': {'en': 'Easier reading for long legal briefs', 'hi': 'लंबे कानूनी नोट्स पढ़ना आसान'},
  'storage_data': {'en': 'STORAGE & DATA', 'hi': 'स्टोरेज और डेटा'},
  'clear_cached_judgments': {'en': 'Clear Cached Judgments', 'hi': 'कैश किए गए फैसले साफ करें'},
  'clear_cached_judgments_subtitle': {'en': 'Free up local device storage (4.2 MB)', 'hi': 'डिवाइस स्टोरेज खाली करें (4.2 MB)'},
  'cache_cleared': {'en': 'Offline judgment cache cleared successfully', 'hi': 'ऑफलाइन फैसलों का कैश साफ हो गया'},
  'account_management': {'en': 'ACCOUNT MANAGEMENT', 'hi': 'अकाउंट प्रबंधन'},
  'delete_account': {'en': 'Delete Account', 'hi': 'अकाउंट डिलीट करें'},
  'delete_account_subtitle': {'en': 'Permanently delete after 7 days if you do not log back in', 'hi': '7 दिन में लॉगिन न करने पर स्थायी रूप से डिलीट होगा'},
  'about_legal': {'en': 'ABOUT & LEGAL', 'hi': 'ऐप और कानूनी जानकारी'},
  'app_version': {'en': 'App Version', 'hi': 'ऐप वर्जन'},
  'privacy_policy': {'en': 'Privacy Policy', 'hi': 'प्राइवेसी पॉलिसी'},
  'terms_of_service': {'en': 'Terms of Service', 'hi': 'सेवा की शर्तें'},
  'quick_search_hint': {'en': 'Search case name, citation, or keywords...', 'hi': 'केस नाम, उद्धरण या कीवर्ड खोजें...'},
  'key_bare_acts': {'en': 'Key Bare Acts', 'hi': 'मुख्य बेयर एक्ट्स'},
  'view_all': {'en': 'View All', 'hi': 'सभी देखें'},
  'landmark_judgments': {'en': 'Landmark Judgments', 'hi': 'महत्वपूर्ण फैसले'},
  'verified_legal_updates': {'en': 'Verified Legal Updates', 'hi': 'सत्यापित कानूनी अपडेट'},
  'good_morning': {'en': 'Good Morning,', 'hi': 'सुप्रभात,'},
  'good_afternoon': {'en': 'Good Afternoon,', 'hi': 'शुभ दोपहर,'},
  'good_evening': {'en': 'Good Evening,', 'hi': 'शुभ संध्या,'},
  'good_night': {'en': 'Good Night,', 'hi': 'शुभ रात्रि,'},
  'learn_explore_grow': {'en': 'Learn • Explore • Grow', 'hi': 'सीखें • खोजें • बढ़ें'},
  'my_posts': {'en': 'My Posts', 'hi': 'मेरी पोस्ट'},
  'my_notes': {'en': 'My Notes', 'hi': 'मेरे नोट्स'},
  'reading_history': {'en': 'Reading History', 'hi': 'रीडिंग हिस्ट्री'},
  'help_support': {'en': 'Help & Support', 'hi': 'मदद और सपोर्ट'},
  'about_us': {'en': 'About Us', 'hi': 'हमारे बारे में'},
  'log_out': {'en': 'Log Out', 'hi': 'लॉग आउट'},
  'tap_to_explore': {'en': 'Tap to explore', 'hi': 'देखने के लिए टैप करें'},
};
