// Pharmory App Configuration
// TODO: Move sensitive data to secure storage

class AppConfig {
  // API Keys - IMPORTANT: Replace with your actual keys
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  // App Configuration
  static const String appName = 'Pharmory';
  static const String appVersion = '1.0.0';
  
  // Supported languages
  static const List<String> supportedLanguages = ['tr', 'en'];
  static const String defaultLanguage = 'tr';
  
  // Font size limits
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  static const double defaultFontSize = 16.0;
  
  // Search configuration
  static const int maxSearchHistory = 10;
  static const int searchTimeoutSeconds = 30;
  
  // File upload limits
  static const int maxImageSizeMB = 10;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  
  // API Endpoints
  static String get geminiApiUrl => 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey';
  
  // Error messages
  static const Map<String, String> errorMessages = {
    'no_internet': 'İnternet bağlantısı yok',
    'api_error': 'API hatası oluştu',
    'invalid_medication': 'Geçersiz ilaç adı',
    'no_results': 'Sonuç bulunamadı',
    'ocr_failed': 'Metin çıkarılamadı',
    'save_failed': 'Kaydetme başarısız',
  };
  
  // Success messages
  static const Map<String, String> successMessages = {
    'search_completed': 'Arama tamamlandı',
    'feedback_sent': 'Geri bildirim gönderildi',
    'info_updated': 'Bilgi güncellendi',
    'saved_to_history': 'Geçmişe kaydedildi',
  };
  
  // Validation
  static bool isValidGeminiKey(String key) {
    return key.isNotEmpty && 
           key != 'YOUR_GEMINI_API_KEY_HERE' && 
           key.startsWith('AIza');
  }
  
  static bool isValidSupabaseUrl(String url) {
    return url.isNotEmpty && 
           url != 'YOUR_SUPABASE_URL_HERE' && 
           url.startsWith('https://');
  }
  
  static bool isValidSupabaseKey(String key) {
    return key.isNotEmpty && key != 'YOUR_SUPABASE_ANON_KEY_HERE';
  }
}
