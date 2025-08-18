import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/ocr_service.dart';
import '../models/api_response.dart';
import '../models/medication.dart';
import 'result_screen.dart';
import '../widgets/accessibility_controls.dart';
import '../widgets/search_history_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final ApiService _apiService = ApiService();
  final OCRService _ocrService = OCRService();
  final ImagePicker _imagePicker = ImagePicker();
  
  String? _selectedImagePath;
  String? _selectedImageName;
  List<int>? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _ocrService.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  // Search medication by name
  Future<void> _searchMedication() async {
    final searchTerm = _searchController.text.trim();
    
    if (searchTerm.isEmpty) {
      _showSnackBar('Lütfen bir ilaç adı girin', isError: true);
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.setLoading(true);

    try {
      final request = SearchRequest(
        medicationName: searchTerm,
        language: appProvider.language,
      );

      final response = await _apiService.searchMedication(request);
      
      if (response.success && response.data != null) {
        await appProvider.addToSearchHistory(searchTerm);
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(medication: response.data!),
            ),
          );
        }
      } else {
        _showSnackBar(response.error ?? 'İlaç bulunamadı', isError: true);
      }
    } catch (e) {
      _showSnackBar('Bir hata oluştu: $e', isError: true);
    } finally {
      appProvider.setLoading(false);
    }
  }

  // Pick and process image
  Future<void> _pickImage(ImageSource source) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      // Read image bytes immediately for web compatibility
      final bytes = await image.readAsBytes();
      
      setState(() {
        _selectedImagePath = image.path;
        _selectedImageName = image.name;
        _selectedImageBytes = bytes;
      });

      // Analyze image directly for medication info
      _showSnackBar('Fotoğraf analiz ediliyor...');
      await _analyzeImageForMedication(bytes);
      
    } catch (e) {
      _showSnackBar('Fotoğraf seçilirken hata oluştu: $e', isError: true);
    }
  }

  // Clear selected image
  void _clearSelectedImage() {
    setState(() {
      _selectedImagePath = null;
      _selectedImageName = null;
      _selectedImageBytes = null;
    });
  }

  // Analyze image for medication information
  Future<void> _analyzeImageForMedication(List<int> imageBytes) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.setLoading(true);

    try {
      final request = SearchRequest(
        imageBytes: imageBytes,
        language: appProvider.language,
      );

      final response = await _apiService.searchMedication(request);
      
      if (response.success && response.data != null) {
        // Add medication name to search history
        await appProvider.addToSearchHistory(response.data!.name);
        
        // Clear selected image
        _clearSelectedImage();
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(medication: response.data!),
            ),
          );
        }
              } else {
          String errorMessage = response.error ?? 'Fotoğraftan ilaç bilgisi çıkarılamadı';
          _showSnackBar(errorMessage, isError: true);
          _clearSelectedImage();
          
          // If quota error, focus on text input
          if (errorMessage.contains('quota')) {
            FocusScope.of(context).requestFocus(_textFocusNode);
            _showSnackBar('💡 İlaç adını yazarak arama yapabilirsiniz', isError: false);
          }
        }
    } catch (e) {
      _showSnackBar('Fotoğraf analizi sırasında hata oluştu: $e', isError: true);
      _clearSelectedImage();
    } finally {
      appProvider.setLoading(false);
    }
  }

  // Search using OCR text
  Future<void> _searchByOCR(String ocrText) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    try {
      final request = SearchRequest(
        ocrText: ocrText,
        language: appProvider.language,
      );

      final response = await _apiService.searchMedication(request);
      
      if (response.success && response.data != null) {
        await appProvider.addToSearchHistory(response.data!.name);
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(medication: response.data!),
            ),
          );
        }
      } else {
        _showSnackBar(response.error ?? 'İlaç bilgisi bulunamadı', isError: true);
      }
    } catch (e) {
      _showSnackBar('Arama sırasında hata oluştu: $e', isError: true);
    }
  }

  // Show image source selection
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğraf Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pharmory'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accessibility controls
                  const AccessibilityControls(),
                  
                  const SizedBox(height: 24),
                  
                  // Welcome text
                  Text(
                    'İlaç Bilgi Asistanınız',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'İlaç adını yazın veya prospektüsün fotoğrafını çekin',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Search input
                  TextField(
                    controller: _searchController,
                    focusNode: _textFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'İlaç adını girin (örn: Parol, Aspirin)',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Icon(Icons.medication),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchMedication(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Search button
                  ElevatedButton(
                    onPressed: appProvider.isLoading ? null : _searchMedication,
                    child: appProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('ARA'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Divider with "VEYA"
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'VEYA',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Camera button
                  OutlinedButton.icon(
                    onPressed: appProvider.isLoading ? null : _showImageSourceDialog,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Prospektüs Fotoğrafı Çek'),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Search history
                  if (appProvider.searchHistory.isNotEmpty) ...[
                    Text(
                      'Son Aramalar',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SearchHistoryWidget(
                        searchHistory: appProvider.searchHistory,
                        onSearchTap: (searchTerm) {
                          _searchController.text = searchTerm;
                          _searchMedication();
                        },
                        onClearHistory: appProvider.clearSearchHistory,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
