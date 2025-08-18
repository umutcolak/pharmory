import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final Logger _logger = Logger();
  
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Initialize TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set Turkish language
      await _flutterTts.setLanguage('tr-TR');
      
      // Set speech rate (0.0 to 1.0)
      await _flutterTts.setSpeechRate(0.5);
      
      // Set volume (0.0 to 1.0)
      await _flutterTts.setVolume(0.8);
      
      // Set pitch (0.5 to 2.0)
      await _flutterTts.setPitch(1.0);

      // Set callbacks
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _logger.i('TTS started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _logger.i('TTS completed speaking');
      });

      _flutterTts.setErrorHandler((message) {
        _isSpeaking = false;
        _logger.e('TTS error: $message');
      });

      _isInitialized = true;
      _logger.i('TTS service initialized successfully');
    } catch (e) {
      _logger.e('Error initializing TTS: $e');
    }
  }

  // Speak text
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (_isSpeaking) {
        await stop();
      }

      await _flutterTts.speak(text);
      _logger.i('Speaking: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
    } catch (e) {
      _logger.e('Error speaking text: $e');
    }
  }

  // Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _logger.i('TTS stopped');
    } catch (e) {
      _logger.e('Error stopping TTS: $e');
    }
  }

  // Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _logger.i('TTS paused');
    } catch (e) {
      _logger.e('Error pausing TTS: $e');
    }
  }

  // Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  // Get available languages
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      _logger.e('Error getting languages: $e');
      return [];
    }
  }

  // Set language
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      _logger.i('TTS language set to: $language');
    } catch (e) {
      _logger.e('Error setting language: $e');
    }
  }

  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      _logger.i('TTS speech rate set to: $rate');
    } catch (e) {
      _logger.e('Error setting speech rate: $e');
    }
  }

  // Speak medication information in structured way
  Future<void> speakMedicationInfo(String medicationName, String usage, String dosage, List<String> sideEffects) async {
    final text = '''
    İlaç adı: $medicationName.
    
    Kullanım amacı: $usage.
    
    Dozaj bilgisi: $dosage.
    
    Yan etkiler: ${sideEffects.join(', ')}.
    ''';
    
    await speak(text);
  }

  // Dispose
  void dispose() {
    _flutterTts.stop();
    _isInitialized = false;
    _isSpeaking = false;
  }
}
