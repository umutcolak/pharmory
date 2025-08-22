import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/medication.dart';
import '../models/api_response.dart';
import '../config/app_config.dart';

class ApiService {
  
  final Logger _logger = Logger();
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Gemini headers
  Map<String, String> get _geminiHeaders => {
    'Content-Type': 'application/json',
  };
  
  // Supabase headers
  Map<String, String> get _supabaseHeaders => {
    'Content-Type': 'application/json',
    'apikey': AppConfig.supabaseKey,
    'Authorization': 'Bearer ${AppConfig.supabaseKey}',
  };

  // Search for medication - MAIN FLOW
  Future<ApiResponse<Medication>> searchMedication(SearchRequest request) async {
    try {
      String searchTerm = request.medicationName ?? '';
      String? imageBase64;
      
      // If there's an image, extract medication name first, then search normally
      if (request.imageBytes != null && request.imageBytes!.isNotEmpty) {
        try {
          imageBase64 = base64Encode(request.imageBytes!);
          print('📸 Fotoğraftan ilaç adı çıkarılıyor...');
          
          // Extract medication name from image
          final extractedName = await _extractMedicationNameFromImage(imageBase64);
          if (extractedName == null || extractedName.isEmpty) {
            return ApiResponse.error('Fotoğraftan ilaç adı okunamadı');
          }
          
          print('✅ Fotoğraftan ilaç adı çıkarıldı: $extractedName');
          print('🔄 Normal text search ile doğru bilgiler alınıyor...');
          
          // Now search with the extracted name using normal text search
          searchTerm = extractedName.toLowerCase().trim();
          
        } catch (e) {
          _logger.e('Error processing image: $e');
          
          // If image processing fails, ask user to enter medication name manually
          return ApiResponse.error('Fotoğraf işlenemedi (quota sınırı). Lütfen ilaç adını yazarak arama yapın.');
        }
      }
      
      // OCR text handling
      if (request.ocrText != null && request.ocrText!.isNotEmpty) {
        searchTerm = _extractMedicationFromOCR(request.ocrText!);
      }
      
      if (searchTerm.isEmpty) {
        return ApiResponse.error('İlaç adı bulunamadı');
      }
      
      searchTerm = searchTerm.toLowerCase().trim();
      _logger.i('Searching for medication: $searchTerm');
      
      // For image analysis, skip database search and go directly to Gemini
      if (imageBase64 == null) {
        // 1. First check Supabase database (if configured)
        if (AppConfig.isValidSupabaseUrl(AppConfig.supabaseUrl) && AppConfig.isValidSupabaseKey(AppConfig.supabaseKey)) {
          final existingMedication = await _searchInDatabase(searchTerm);
          if (existingMedication != null) {
            _logger.i('Found medication in database: ${existingMedication.name}');
            return ApiResponse.success(existingMedication, message: 'İlaç bilgisi veritabanından getirildi');
          }
        } else {
          _logger.i('Supabase not configured, skipping database search');
        }
      }
      
      // 2. If not found in database, query Gemini with smart search
      _logger.i('Medication not found in database, querying Gemini...');
      
      // Try exact search first
      Medication? aiMedication = await _queryGemini(searchTerm, request.language);
      
      // If no results or "bilgi bulunamadı", try with common variations
      if (aiMedication == null || 
          aiMedication.name.toLowerCase().contains('bilgi bulunamadı') ||
          aiMedication.description.toLowerCase().contains('bilgi bulunamadı')) {
        
        _logger.i('Trying search variations for: $searchTerm');
        
        // Try common medication name patterns
        List<String> variations = [
          '$searchTerm forte',
          '$searchTerm plus',
          searchTerm.replaceAll('-', ' '),
          searchTerm.replaceAll(' ', '-'),
        ];
        
        for (String variation in variations) {
          if (variation != searchTerm) {
            _logger.i('Trying variation: $variation');
            aiMedication = await _queryGemini(variation, request.language);
            
            if (aiMedication != null && 
                !aiMedication.name.toLowerCase().contains('bilgi bulunamadı') &&
                !aiMedication.description.toLowerCase().contains('bilgi bulunamadı')) {
              _logger.i('Found medication with variation: ${aiMedication.name}');
              break;
            }
          }
        }
      }
      
      if (aiMedication == null ||
          aiMedication.name.toLowerCase().contains('bilgi bulunamadı') ||
          aiMedication.description.toLowerCase().contains('bilgi bulunamadı')) {
        return ApiResponse.error('İlaç bilgisi bulunamadı. Lütfen ilaç adını kontrol edin.');
      }
      
      // 3. Save to database for future queries (if configured)
      final savedMedication = AppConfig.isValidSupabaseUrl(AppConfig.supabaseUrl) && AppConfig.isValidSupabaseKey(AppConfig.supabaseKey)
          ? await _saveToDatabase(aiMedication)
          : aiMedication;
      
      return ApiResponse.success(
        savedMedication, 
        message: imageBase64 != null 
            ? 'İlaç bilgisi fotoğraftan AI ile çıkarıldı'
            : (AppConfig.isValidSupabaseUrl(AppConfig.supabaseUrl) 
                ? 'İlaç bilgisi AI\'dan getirildi ve kaydedildi'
                : 'İlaç bilgisi AI\'dan getirildi')
      );
      
    } catch (e) {
      _logger.e('Error in searchMedication: $e');
      return ApiResponse.error('Arama sırasında hata oluştu: $e');
    }
  }

  // Search medication in Supabase database
  Future<Medication?> _searchInDatabase(String medicationName) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/medications?name=ilike.*$medicationName*&limit=1'),
        headers: _supabaseHeaders,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return Medication.fromJson(data.first);
        }
      }
      return null;
    } catch (e) {
      _logger.e('Error searching in database: $e');
      return null;
    }
  }

  // Query Gemini with image for full medication information
  Future<Medication?> _queryGeminiWithImage(String imageBase64, String language) async {
    try {
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': imageBase64
                }
              },
              {
                'text': _getImageAnalysisPrompt(language)
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 2000,
        }
      };

      print('🚀 Gemini Vision API çağrısı yapılıyor...');
      
      final response = await http.post(
        Uri.parse(AppConfig.geminiApiUrl),
        headers: _geminiHeaders,
        body: jsonEncode(requestBody),
      );

      print('📡 Gemini yanıt kodu: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        print('✅ Gemini yanıtı alındı: ${content.substring(0, 100)}...');
        
        // Extract JSON from the response
        String jsonContent = content;
        if (content.contains('{')) {
          final startIndex = content.indexOf('{');
          final endIndex = content.lastIndexOf('}') + 1;
          jsonContent = content.substring(startIndex, endIndex);
        }
        
        final medicationData = jsonDecode(jsonContent);
        
        return Medication(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: medicationData['name'] ?? 'Bilinmeyen İlaç',
          description: medicationData['description'] ?? '',
          usage: medicationData['usage'] ?? '',
          dosage: medicationData['dosage'] ?? '',
          sideEffects: List<String>.from(medicationData['side_effects'] ?? []),
          warnings: List<String>.from(medicationData['warnings'] ?? []),
          indications: List<String>.from(medicationData['indications'] ?? []),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: false,
        );
      } else {
        _logger.e('Gemini Vision API error: ${response.statusCode} - ${response.body}');
        print('❌ Gemini Vision API Hatası: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error querying Gemini with image: $e');
      print('❌ Gemini Vision çağrısında hata: $e');
      return null;
    }
  }

  // Query Gemini for medication information (text only)
  Future<Medication?> _queryGemini(String medicationName, String language) async {
    try {
      // Security check for inappropriate content
      if (_containsInappropriateContent(medicationName)) {
        _logger.w('Inappropriate content detected: $medicationName');
        return null;
      }
      
      final prompt = _createPrompt(medicationName, language);
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '${_getSystemPrompt(language)}\n\n$prompt'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 2000,
        }
      };

      print('🚀 Gemini API çağrısı yapılıyor: $medicationName');
      
      final response = await http.post(
        Uri.parse(AppConfig.geminiApiUrl),
        headers: _geminiHeaders,
        body: jsonEncode(requestBody),
      );

      print('📡 Gemini yanıt kodu: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        print('✅ Gemini yanıtı alındı: ${content.substring(0, 100)}...');
        
        // Extract JSON from the response (Gemini might return text with JSON)
        String jsonContent = content;
        if (content.contains('{')) {
          final startIndex = content.indexOf('{');
          final endIndex = content.lastIndexOf('}') + 1;
          jsonContent = content.substring(startIndex, endIndex);
        }
        
        final medicationData = jsonDecode(jsonContent);
        
        return Medication(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: medicationData['name'] ?? medicationName,
          description: medicationData['description'] ?? '',
          usage: medicationData['usage'] ?? '',
          dosage: medicationData['dosage'] ?? '',
          sideEffects: List<String>.from(medicationData['side_effects'] ?? []),
          warnings: List<String>.from(medicationData['warnings'] ?? []),
          indications: List<String>.from(medicationData['indications'] ?? []),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: false, // AI generated, needs verification
        );
      } else {
        _logger.e('Gemini API error: ${response.statusCode} - ${response.body}');
        print('❌ Gemini API Hatası: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error querying Gemini: $e');
      print('❌ Gemini çağrısında hata: $e');
      return null;
    }
  }

  // Save medication to Supabase database
  Future<Medication> _saveToDatabase(Medication medication) async {
    try {
      final data = medication.toJson();
      
      final response = await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/medications'),
        headers: _supabaseHeaders,
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        _logger.i('Medication saved to database: ${medication.name}');
        return Medication.fromJson(responseData.first);
      } else {
        _logger.e('Error saving to database: ${response.statusCode} - ${response.body}');
        return medication; // Return original if save fails
      }
    } catch (e) {
      _logger.e('Error saving to database: $e');
      return medication; // Return original if save fails
    }
  }

  // Submit feedback and update medication info
  Future<ApiResponse<Medication>> submitFeedback(FeedbackRequest request) async {
    try {
      _logger.i('Submitting feedback: ${request.toJson()}');
      
      // Get current medication from database
      final currentMedication = await _getMedicationById(request.medicationId);
      if (currentMedication == null) {
        return ApiResponse.error('İlaç bulunamadı');
      }
      
      // Query Gemini for updated information
      final updatedMedication = await _queryGemini(currentMedication.name, request.language);
      if (updatedMedication == null) {
        return ApiResponse.error('Güncellenmiş bilgi alınamadı');
      }
      
      // Update in database
      final saved = await _updateInDatabase(request.medicationId, updatedMedication);
      
      return ApiResponse.success(saved, message: 'İlaç bilgisi güncellendi');
    } catch (e) {
      _logger.e('Error in submitFeedback: $e');
      return ApiResponse.error('Geri bildirim gönderilirken hata oluştu: $e');
    }
  }

  // Get medication by ID from database
  Future<Medication?> _getMedicationById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/medications?id=eq.$id'),
        headers: _supabaseHeaders,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return Medication.fromJson(data.first);
        }
      }
      return null;
    } catch (e) {
      _logger.e('Error getting medication by ID: $e');
      return null;
    }
  }

  // Update medication in database
  Future<Medication> _updateInDatabase(String id, Medication medication) async {
    try {
      final data = medication.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await http.patch(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/medications?id=eq.$id'),
        headers: _supabaseHeaders,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        _logger.i('Medication updated in database');
        return medication;
      } else {
        _logger.e('Error updating in database: ${response.statusCode}');
        return medication;
      }
    } catch (e) {
      _logger.e('Error updating in database: $e');
      return medication;
    }
  }

  // Extract medication name from image using Gemini Vision
  Future<String?> _extractMedicationNameFromImage(String imageBase64) async {
    try {
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': imageBase64
                }
              },
              {
                'text': 'Bu ilaç kutusu/prospektüs fotoğrafında ilaç adını bul. SADECE İLAÇ ADINI döndür, başka hiçbir şey yazma. Eğer ilaç adı net değilse "BULUNAMADI" yaz. Örnekler: "Parol", "A-Ferin Forte", "Aspirin"'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 50,
        }
      };

      final response = await http.post(
        Uri.parse(AppConfig.geminiApiUrl),
        headers: _geminiHeaders,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        
        String medicationName = content.trim();
        
        // Clean up the response
        if (medicationName.toLowerCase().contains('bulunamadi') || 
            medicationName.toLowerCase().contains('bulunamadı')) {
          return null;
        }
        
        // Remove common prefixes/suffixes and clean
        medicationName = medicationName.replaceAll(RegExp(r'^(ilaç|medicine|drug|tablet)\s*:?\s*', caseSensitive: false), '');
        medicationName = medicationName.replaceAll(RegExp(r'\s*(tablet|capsule|mg|gr|ml)\s*$', caseSensitive: false), '');
        medicationName = medicationName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
        
        return medicationName.isNotEmpty ? medicationName : null;
      } else {
        _logger.e('Gemini Vision API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error extracting medication name from image: $e');
      return null;
    }
  }

  // Extract medication name from OCR text
  String _extractMedicationFromOCR(String ocrText) {
    // Simple extraction - look for capitalized words
    final words = ocrText.split(' ');
    for (final word in words) {
      if (word.length > 3 && word.length < 20 && 
          RegExp(r'^[A-ZĞİÖŞÜÇ][a-zğıöşüç]+').hasMatch(word)) {
        return word;
      }
    }
    // Return first reasonable word if no pattern matches
    return words.where((w) => w.length > 3).first;
  }

  // Create prompt for OpenAI
  String _createPrompt(String medicationName, String language) {
    if (language == 'tr') {
      return '''
$medicationName isimli ilaç hakkında detaylı bilgi ver.

Aşağıdaki JSON formatında yanıt ver:
{
  "name": "İlaç adı",
  "description": "İlacın kısa açıklaması",
  "usage": "Hangi durumlarda kullanılır",
  "dosage": "Genel dozaj bilgisi",
  "side_effects": ["Yan etki 1", "Yan etki 2"],
  "warnings": ["Uyarı 1", "Uyarı 2"],
  "indications": ["Endikasyon 1", "Endikasyon 2"]
}
''';
    } else {
      return '''
Provide detailed information about the medication: $medicationName

Respond in this JSON format:
{
  "name": "Medication name",
  "description": "Brief description",
  "usage": "What conditions it's used for",
  "dosage": "General dosage information",
  "side_effects": ["Side effect 1", "Side effect 2"],
  "warnings": ["Warning 1", "Warning 2"],
  "indications": ["Indication 1", "Indication 2"]
}
''';
    }
  }

  // Get system prompt for Gemini
  // Get image analysis prompt for medication information
  // Security check for inappropriate content
  bool _containsInappropriateContent(String text) {
    final String lowerText = text.toLowerCase().trim();
    
    // Check if it's clearly not a medication name
    if (lowerText.length < 2) return true;
    
    // List of inappropriate keywords
    final List<String> inappropriateWords = [
      // Sexual content
      'sex', 'porn', 'xxx', 'nude', 'naked', 'erotic',
      // Violence/Drugs
      'kill', 'murder', 'death', 'suicide', 'bomb', 'gun',
      'cocaine', 'heroin', 'cannabis', 'marijuana', 'drugs',
      // Turkish inappropriate terms
      'seks', 'porno', 'çıplak', 'nü', 'erotik',
      'öldür', 'ölüm', 'intihar', 'bomba', 'silah',
      'kokain', 'eroin', 'esrar', 'uyuşturucu',
      // Offensive terms
      'fuck', 'shit', 'damn', 'bitch', 'asshole',
      'amk', 'sik', 'göt', 'am', 'yarrak', 'orospu'
    ];
    
    // Check for inappropriate words
    for (String word in inappropriateWords) {
      if (lowerText.contains(word)) {
        return true;
      }
    }
    
    // Check for suspicious patterns
    if (RegExp(r'[!@#$%^&*()_+=\[\]{}|;:",.<>?/~`]{3,}').hasMatch(lowerText)) {
      return true;
    }
    
    // Check for repeated characters (spam-like)
    if (RegExp(r'(.)\1{4,}').hasMatch(lowerText)) {
      return true;
    }
    
    return false;
  }

  String _getImageAnalysisPrompt(String language) {
    if (language == 'en') {
      return '''Analyze this medication image (box, package, or leaflet) and provide detailed information about the medication in JSON format.

Look at the image carefully and identify:
1. The medication name
2. Active ingredients
3. Dosage information
4. Usage instructions
5. Side effects (if visible)
6. Warnings (if visible)
7. Indications (what it's used for)

Respond ONLY with a JSON object in this exact format:
{
  "name": "Medication name",
  "description": "Brief description of what this medication is",
  "usage": "How to use this medication",
  "dosage": "Dosage information",
  "side_effects": ["side effect 1", "side effect 2"],
  "warnings": ["warning 1", "warning 2"],
  "indications": ["indication 1", "indication 2"]
}

If you cannot clearly identify the medication or read the text, respond with:
{"error": "Cannot identify medication from image"}''';
    } else {
      return '''Bu ilaç görselini (kutu, ambalaj veya prospektüs) analiz et ve ilacın detaylı bilgilerini JSON formatında ver.

GÜVENLİK KURALLARI:
- SADECE ilaç ve tıbbi ürün görselleri kabul et
- Uygunsuz, pornografik içerik tespit edersen reddet
- İlaç dışı görsel varsa analiz etme

Görseli dikkatli incele ve şunları belirle:
1. İlaç adı
2. Etken maddeler
3. Doz bilgileri
4. Kullanım talimatları
5. Yan etkiler (görünüyorsa)
6. Uyarılar (görünüyorsa)
7. Endikasyonlar (ne için kullanıldığı)

SADECE bu JSON formatında yanıt ver:
{
  "name": "İlaç adı",
  "description": "Bu ilacın ne olduğuna dair kısa açıklama",
  "usage": "Bu ilacın nasıl kullanılacağı",
  "dosage": "Doz bilgileri",
  "side_effects": ["yan etki 1", "yan etki 2"],
  "warnings": ["uyarı 1", "uyarı 2"],
  "indications": ["endikasyon 1", "endikasyon 2"]
}

Eğer ilacı net olarak tanımlayamıyor veya metni okuyamıyorsan:
{"error": "Görselden ilaç tanımlanamadı"}

Eğer uygunsuz içerik tespit edersen:
{"error": "Uygunsuz içerik tespit edildi"}''';
    }
  }

  String _getSystemPrompt(String language) {
    if (language == 'tr') {
      return '''
Sen bir eczacılık uzmanısın. İlaçlar hakkında doğru, güvenilir ve anlaşılır bilgiler sağlıyorsun.

GÜVENLİK KURALLARI:
- SADECE ilaç ve tıbbi ürünler hakkında bilgi ver
- Uygunsuz, pornografik, şiddet içerikli sorulara ASLA yanıt verme
- Yasal olmayan madde/uyuşturucu sorularını reddet
- Şüpheli istek varsa "Bu tür sorulara yanıt veremem" de

KURALLAR:
1. Sadece genel ilaç bilgileri ver, spesifik tıbbi tavsiye verme
2. Bilgi bulunmuyorsa "Bilgi bulunamadı" belirt
3. Güvenlik uyarılarını mutlaka ekle
4. SADECE ve SADECE JSON formatında yanıt ver, başka hiçbir metin ekleme
5. Her zaman doktor/eczacı danışmanlığı uyarısı ekle
6. JSON'ın dışında herhangi bir açıklama veya metin yazma

Yanıtın MUTLAKA bu formatta olsun:
{
  "name": "İlaç adı",
  "description": "İlacın kısa açıklaması",
  "usage": "Hangi durumlarda kullanılır",
  "dosage": "Genel dozaj bilgisi",
  "side_effects": ["Yan etki 1", "Yan etki 2"],
  "warnings": ["Uyarı 1", "Uyarı 2"],
  "indications": ["Endikasyon 1", "Endikasyon 2"]
}
''';
    } else {
      return '''
You are a pharmaceutical expert providing accurate, reliable medication information.

SECURITY RULES:
- ONLY provide information about medications and medical products
- NEVER respond to inappropriate, pornographic, or violent content
- Reject questions about illegal substances/drugs
- If suspicious request, respond "I cannot answer such questions"

RULES:
1. Only provide general medication information, no specific medical advice
2. If information is not available, state "Information not found"
3. Always include safety warnings
4. Respond ONLY in JSON format, no additional text
5. Always include doctor/pharmacist consultation warning
6. Do not add any explanation or text outside the JSON

Your response MUST be in this format:
{
  "name": "Medication name",
  "description": "Brief description",
  "usage": "What conditions it's used for",
  "dosage": "General dosage information",
  "side_effects": ["Side effect 1", "Side effect 2"],
  "warnings": ["Warning 1", "Warning 2"],
  "indications": ["Indication 1", "Indication 2"]
}
''';
    }
  }

  // Health check (for testing)
  Future<bool> checkHealth() async {
    try {
      // Test Supabase connection
      final response = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/medications?limit=1'),
        headers: _supabaseHeaders,
      );
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Health check failed: $e');
      return false;
    }
  }
}