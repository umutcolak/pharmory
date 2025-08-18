import 'dart:io';
import 'dart:convert';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:logger/logger.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final Logger _logger = Logger();
  late TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  // Initialize OCR
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _isInitialized = true;
      _logger.i('OCR service initialized successfully');
    } catch (e) {
      _logger.e('Error initializing OCR: $e');
    }
  }

  // Extract text from image file
  Future<String?> extractTextFromImage(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final extractedText = recognizedText.text;
      _logger.i('OCR extracted text length: ${extractedText.length}');
      _logger.d('OCR extracted text: $extractedText');
      
      return extractedText.isNotEmpty ? extractedText : null;
    } catch (e) {
      _logger.e('Error extracting text from image: $e');
      return null;
    }
  }

  // Convert image to base64 for API
  Future<String?> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      _logger.i('Image converted to base64, length: ${base64String.length}');
      return base64String;
    } catch (e) {
      _logger.e('Error converting image to base64: $e');
      return null;
    }
  }

  // Extract medication name from OCR text using pattern matching
  String? extractMedicationName(String text) {
    try {
      // Clean the text
      final cleanText = text.replaceAll('\n', ' ').trim();
      
      // Common patterns for medication names in Turkish prescriptions
      final patterns = [
        // Pattern 1: "İlaç adı:" or similar
        RegExp(r'(?:ilaç adı|ilaç|name|drug)[\s:]+([A-Za-zğĞıİöÖşŞüÜçÇ\s]+)', caseSensitive: false),
        
        // Pattern 2: Brand names (usually capitalized words)
        RegExp(r'\b([A-ZĞİÖŞÜÇ][a-zğıöşüç]+(?:\s+[A-ZĞİÖŞÜÇ][a-zğıöşüç]+)?)\b'),
        
        // Pattern 3: Generic names ending with common suffixes
        RegExp(r'\b([a-zğıöşüç]+(?:ol|in|am|ic|ate|ide|ine|one|ium))\b', caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final matches = pattern.allMatches(cleanText);
        for (final match in matches) {
          final candidate = match.group(1)?.trim();
          if (candidate != null && candidate.length > 2 && candidate.length < 30) {
            _logger.i('Extracted medication name candidate: $candidate');
            return candidate;
          }
        }
      }

      // If no pattern matches, return the first reasonable word
      final words = cleanText.split(' ').where((word) => 
        word.length > 3 && 
        word.length < 20 && 
        RegExp(r'^[A-Za-zğĞıİöÖşŞüÜçÇ]+$').hasMatch(word)
      ).toList();

      if (words.isNotEmpty) {
        _logger.i('Using first word as medication name: ${words.first}');
        return words.first;
      }

      return null;
    } catch (e) {
      _logger.e('Error extracting medication name: $e');
      return null;
    }
  }

  // Clean OCR text for better processing
  String cleanOCRText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r'[^\w\s.,;:()/-]'), '') // Remove special characters except basic punctuation
        .trim();
  }

  // Dispose
  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
      _isInitialized = false;
    }
  }
}
