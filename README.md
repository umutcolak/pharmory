# 💊 Pharmory - AI Destekli İlaç Bilgi iOS Uygulaması

Pharmory, Flutter ile geliştirilmiş, AI destekli ilaç bilgi uygulamasıdır. Kullanıcılar ilaç adını arayabilir veya prospektüs fotoğrafı çekerek ilaç bilgilerine ulaşabilir.

## 🎯 Özellikler

### 📱 **Native iOS Uygulaması (Flutter)**
- 🔍 **İlaç Arama**: İsimle arama ve Gemini Vision destekli prospektüs tarama
- 🧠 **Smart Search**: Bilgi bulunamadığında otomatik varyasyon denemesi
- 📸 **Hybrid Image Analysis**: Fotoğraftan isim çıkar → text search ile tutarlı sonuçlar
- 🗣️ **Sesli Okuma**: Yaşlı dostu TTS (Text-to-Speech) desteği
- ♿ **Erişilebilirlik**: Büyük font, basit UI, yüksek kontrast
- 📊 **Arama Geçmişi**: Son aramaları kaydetme ve hızlı erişim
- 🔄 **Geri Bildirim**: Yanlış bilgileri bildirme ve güncelleme

### 🤖 **AI Entegrasyonu**
- 🧠 **Google Gemini**: Direkt API çağrısı ile ilaç bilgisi üretimi (ücretsiz/daha ucuz)
- 💾 **Akıllı Önbellekleme**: İlk aramada AI, sonrasında Supabase'den hızlı veri
- 🔄 **Dinamik Güncelleme**: Kullanıcı geri bildirimiyle bilgileri yeniden alma

### 🗄️ **Veritabanı (Supabase)**
- 📊 **PostgreSQL**: Direkt Flutter'dan Supabase REST API
- 🔍 **Akıllı Arama**: Türkçe dil desteğiyle gelişmiş arama
- 📈 **Analitik**: Arama geçmişi ve kullanıcı geri bildirimleri

## 🏗️ Proje Yapısı

```
pharmory/
├── 📱 lib/                           # Flutter iOS Uygulaması (Pure - No Backend!)
│   ├── main.dart                     # Ana uygulama
│   ├── config/
│   │   └── app_config.dart           # API anahtarları ve ayarlar
│   ├── models/                       # Veri modelleri
│   │   ├── medication.dart           # İlaç modeli
│   │   └── api_response.dart         # API yanıt modeli
│   ├── providers/                    # State management
│   │   └── app_provider.dart         # Uygulama state'i
│   ├── screens/                      # Ana ekranlar
│   │   ├── home_screen.dart          # Ana sayfa (Smart Search)
│   │   └── result_screen.dart        # Sonuç sayfası
│   ├── services/                     # API servisleri (Flutter-only)
│   │   ├── api_service.dart          # Gemini & Supabase entegrasyonu
│   │   ├── ocr_service.dart          # Gemini Vision wrapper
│   │   └── tts_service.dart          # Sesli okuma
│   ├── theme/                        # UI tema
│   │   └── app_theme.dart            # Yaşlı dostu tasarım
│   └── widgets/                      # UI bileşenleri
│       ├── accessibility_controls.dart
│       ├── feedback_dialog.dart
│       ├── medication_info_card.dart
│       └── search_history_widget.dart
│
├── 🗄️ database/
│   └── supabase_setup.sql            # Veritabanı kurulum script'i
│
├── 🍏 ios/                           # iOS konfigürasyonu
├── 📦 assets/                        # Uygulama varlıkları
├── 🧪 test/                          # Flutter testleri
└── 📚 Dokümantasyon
```

## 🚀 Hızlı Başlangıç

### 📋 Gereksinimler

- **Flutter SDK**: 3.0+
- **Xcode**: iOS geliştirme için
- **Google Gemini API Key**: AI özellikleri için (ücretsiz!)
- **Supabase Account**: Veritabanı için

### 1️⃣ Flutter Kurulumu

```bash
# Projeyi klonla
git clone [repo-url]
cd pharmory

# Bağımlılıkları yükle
flutter pub get

# iOS Simulator'u başlat
open -a Simulator

# Uygulamayı çalıştır
flutter run
```

### 2️⃣ API Anahtarlarını Ayarlama

`lib/config/app_config.dart` dosyasını düzenleyin:

```dart
class AppConfig {
  // BURAYA KENDİ API ANAHTARLARINIZI GİRİN
  static const String geminiApiKey = 'AIzaSy...'; // Google Gemini API key
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseKey = 'your-supabase-anon-key';
}
```

### 3️⃣ Supabase Veritabanı Kurulumu

1. [Supabase](https://supabase.com)'de hesap oluşturun
2. Yeni proje oluşturun
3. SQL editöründe `database/supabase_setup.sql` dosyasını çalıştırın
4. API anahtarlarını `app_config.dart`'a ekleyin

## 🔧 Mimarı

### 📱 **Flutter-Only Mimarı**
- **API Katmanı**: Direkt Google Gemini ve Supabase REST API çağrıları
- **State Yönetimi**: Provider pattern
- **Yerel Depolama**: SharedPreferences (arama geçmişi)
- **Image Analysis**: Gemini Vision API (web uyumlu)
- **TTS**: Flutter TTS plugin

### 🔄 **Veri Akışı**

**📝 Text Search:**
1. **Kullanıcı ilaç adı yazar** → `HomeScreen`
2. **Önce Supabase'de ara** → `ApiService._searchInDatabase()`
3. **Bulunamazsa Gemini'ye git** → `ApiService._queryGemini()`
4. **"Bilgi bulunamadı" ise Smart Search** → otomatik varyasyonlar dene
5. **Sonucu Supabase'e kaydet** → `ApiService._saveToDatabase()`
6. **Kullanıcıya göster** → `ResultScreen`

**📸 Image Search (Hybrid Approach):**
1. **Kullanıcı fotoğraf çeker** → `HomeScreen`
2. **Gemini Vision'a gönder** → `ApiService._extractMedicationNameFromImage()`
3. **İlaç adını çıkar** → sadece isim, bilgi değil
4. **Normal text search yap** → aynı veri akışı
5. **Tutarlı sonuçlar göster** → `ResultScreen`

## 📱 Kullanım Kılavuzu

### 🔍 **İlaç Arama**
1. Uygulamayı açın
2. İlaç adını yazın (örn: "Parol")
3. "ARA" butonuna basın
4. Sonuçları görüntüleyin

### 📸 **Prospektüs Tarama (Smart Hybrid)**
1. "Prospektüs Fotoğrafı Çek" butonuna basın
2. Kamera/Galeri seçin
3. Prospektüs fotoğrafını çekin/seçin
4. **Gemini Vision** ilaç adını tespit eder
5. **Smart Search** ile normal text search yapılır
6. **Tutarlı sonuçlar** text search ile aynı

### 🗣️ **Sesli Okuma**
1. Sonuç sayfasında "Sesli Oku" butonuna basın
2. İlaç bilgileri sesli okunur
3. "Durdurun" butonu ile durdurabilirsiniz

### ♿ **Erişilebilirlik**
1. Ana sayfada yazı boyutunu ayarlayın (12-24px)
2. Dil seçimini yapın (Türkçe/İngilizce)
3. Yüksek kontrast tema otomatik aktif

## 🔑 API Anahtarları Nasıl Alınır

### Google Gemini API Key
1. [Google AI Studio](https://makersuite.google.com/app/apikey)'ya gidin
2. Google hesabınızla giriş yapın
3. "Create API Key" tıklayın
4. API anahtarını kopyalayın (AIzaSy... ile başlar)
5. `app_config.dart` dosyasına ekleyin

### Supabase
1. [Supabase](https://supabase.com/)'de hesap oluşturun
2. "New Project" tıklayın
3. "Settings > API" bölümüne gidin
4. "URL" ve "anon public" anahtarını kopyalayın
5. `app_config.dart`'a ekleyin

## 🧪 Test

```bash
# Widget testlerini çalıştır
flutter test

# Simulator'da test
flutter run --debug

# Release modunda test
flutter run --release
```

## 📱 iOS Deployment

### TestFlight
```bash
# Release build oluştur
flutter build ios --release

# Xcode'da aç
open ios/Runner.xcworkspace

# Archive > Upload to App Store Connect
```

### App Store
1. TestFlight'ta test edin
2. App Store Review'a gönderin
3. Apple onayını bekleyin

## 🛡️ Güvenlik

- ✅ API anahtarları app_config.dart'ta (production'da secure storage kullanın)
- ✅ HTTPS zorunlu (ATS aktif)
- ✅ Input validation
- ✅ Error handling

## ⚠️ Önemli Notlar

- 🏥 **Tıbbi Sorumluluk**: Bu uygulama sadece bilgilendirme amaçlıdır
- 👨‍⚕️ **Doktor Danışmanlığı**: İlaç kullanımında mutlaka uzman görüşü alın
- 🤖 **AI Limitasyonları**: AI üretimi bilgiler doğrulanmalıdır
- 💰 **Maliyet**: Google Gemini API ücretsiz kotası var (daha ekonomik)

## 🔧 Geliştirme

### Yeni Özellik Ekleme
1. `lib/` altında uygun klasöre dosya ekleyin
2. Widget testleri yazın
3. Provider'ları güncelleyin
4. UI bileşenlerini oluşturun

### Debug
```bash
# Log'ları görmek için
flutter logs

# Debug bilgileri
flutter doctor -v
```

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır.

## 🆘 Destek

- 📧 **Issues**: GitHub Issues bölümü
- 📚 **Docs**: README ve kod yorumları
- 🐛 **Bug Reports**: Issue template kullanın

---

**🎉 Pharmory ile ilaç bilgilerine güvenli ve kolay erişim!**

✨ **Pure Flutter iOS App - No Backend Required!**  
🧠 **Smart Search & Hybrid Image Analysis**  
📱 **Text ve Fotoğraf ile Tutarlı Sonuçlar**