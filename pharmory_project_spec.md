# Pharmory — AI Destekli İlaç Bilgi Uygulaması

## 🎯 Amaç

Bu mobil uygulama, kullanıcıların dünya genelindeki ilaçların kullanım talimatlarını öğrenmesine yardımcı olur. Kullanıcılar ya **ilaç ismi** yazarak ya da **ilaç prospektüsünün fotoğrafını** yükleyerek bilgiye ulaşır. Sistem ilk sorguda OpenAI kullanarak içerik üretir ve bunu veritabanına yazar. Daha sonraki aramalarda DB'den veri gösterilir. Kullanıcılar verinin yanlış veya eksik olduğunu bildirerek sistemin AI'a yeniden sormasını tetikleyebilir.

## 🧩 Uygulama Özellikleri

- 📌 Kullanıcı arayüzü (Flutter, sadece iOS)
    - Arama çubuğu (ilaç adı girişi)
    - Görsel yükleme (prospektüs için)
    - Bilgi görüntüleme kartı
    - Sesli okuma butonu
    - Dil seçimi ve yazı tipi büyütme

- 🧠 Yapay Zekâ Entegrasyonu
    - OpenAI ile ilk sorguda ilaç bilgisi oluşturma
    - Kullanıcı bildirimi sonrası veriyi AI ile güncelleme

- 🔄 Backend (FastAPI)
    - `/search`: Arama işlemi, ilk sorguda AI'a sorar, sonra DB'den getirir
    - `/feedback`: Yanlış veri bildirimi, AI ile güncelleyip DB'ye yazar
    - `/ocr`: Yüklenen görselden OCR metin çıkartır

- 🗃️ Veritabanı (Supabase veya Firebase)
    - İlacın adı, kullanım, dozaj, yan etkiler, uyarılar alanları tutulur
    - JSON veri yapısı kullanılır

## 🔁 Kullanım Akışı

1. **Kullanıcı ilaç adı girer** veya **fotoğraf yükler**
2. Backend, önce DB’de arar:
    - Varsa, veri döner
    - Yoksa:
        - OCR (fotoğrafsa)
        - OpenAI'dan bilgi oluştur
        - DB’ye kaydet ve kullanıcıya göster
3. **Kullanıcı veriyi “eksik/yanlış” işaretlerse**
    - Feedback endpoint’i çağrılır
    - AI tekrar yanıt verir, veri güncellenir

## 💡 AI Prompt Örneği

```
Bu bir ilaç prospektüsüdür. Aşağıdaki metni analiz ederek aşağıdaki alanlarda sadeleştirilmiş bilgi ver:

- İlaç adı
- Hangi semptomlar için kullanılır?
- Yan etkileri nelerdir?
- Günde kaç kez kullanılmalıdır?
- Hangi durumlarda kullanılmamalıdır?

Lütfen JSON formatında sade ve anlaşılır olarak yanıtla.
```

## 📱 Flutter UI Sayfa Planı

### 🏠 Ana Sayfa:
- `TextField`: İlaç adı girilecek
- `IconButton`: Kamera/görsel yükleme
- `Dropdown`: Dil seçici
- `Slider`: Yazı büyüklüğü ayarı
- `Button`: Arama yap

### 🧾 Sonuç Sayfası:
- Kart üzerinde:
    - İlaç adı
    - Kullanım alanı
    - Dozaj bilgisi
    - Yan etkiler
    - Uyarılar
- `TextToSpeech`: Sesli oku
- `Button`: Bilgi yanlış → geri bildir

## 🛠️ Teknolojiler

- **Frontend:** Flutter
- **Backend:** FastAPI (Python)
- **OCR:** Tesseract veya OCR.space API
- **AI:** OpenAI GPT-4 API (function calling modunda)
- **DB:** Supabase (alternatif: Firebase Firestore)

## 📚 Ekstra Gereksinimler

- Kullanıcı kimliği zorunlu değil
- Offline kullanım opsiyonu düşünülmüyor (ilk versiyon için)
- App Store ve TestFlight yayını planlanıyor
