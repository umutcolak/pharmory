import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../models/api_response.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../widgets/medication_info_card.dart';
import '../widgets/feedback_dialog.dart';

class ResultScreen extends StatefulWidget {
  final Medication medication;

  const ResultScreen({
    super.key,
    required this.medication,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TTSService _ttsService = TTSService();
  final ApiService _apiService = ApiService();
  final TextEditingController _correctionController = TextEditingController();
  late Medication _currentMedication;
  bool _isUpdating = false;
  bool? _isMedicationCorrect;
  bool _showCorrectionField = false;
  bool _hasValidCorrectionText = false;

  @override
  void initState() {
    super.initState();
    _currentMedication = widget.medication;
    _ttsService.initialize();
    
    // Listen to text changes for button state
    _correctionController.addListener(() {
      setState(() {
        _hasValidCorrectionText = _correctionController.text.trim().isNotEmpty;
      });
    });
    
    // Check if should show history add info on first load
    _checkInitialHistoryAdd();
  }

  @override
  void dispose() {
    _ttsService.stop();
    _correctionController.dispose();
    super.dispose();
  }

  // Speak medication information
  Future<void> _speakMedicationInfo() async {
    try {
      await _ttsService.speakMedicationInfo(
        _currentMedication.name,
        _currentMedication.usage,
        _currentMedication.dosage,
        _currentMedication.sideEffects,
      );
    } catch (e) {
      _showSnackBar('Sesli okuma başlatılamadı: $e', isError: true);
    }
  }

  // Stop speaking
  Future<void> _stopSpeaking() async {
    await _ttsService.stop();
  }

  // Show feedback dialog
  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(
        medication: _currentMedication,
        onFeedbackSubmitted: _handleFeedback,
      ),
    );
  }

  // Handle feedback submission
  Future<void> _handleFeedback(String feedbackType, String? additionalInfo) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final request = FeedbackRequest(
        medicationId: _currentMedication.id,
        feedbackType: feedbackType,
        additionalInfo: additionalInfo,
        language: appProvider.language,
      );

      final response = await _apiService.submitFeedback(request);

      if (response.success && response.data != null) {
        setState(() {
          _currentMedication = response.data!;
        });
        _showSnackBar('Bilgiler güncellendi');
      } else {
        _showSnackBar(response.error ?? 'Güncelleme başarısız', isError: true);
      }
    } catch (e) {
      _showSnackBar('Güncelleme sırasında hata: $e', isError: true);
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  // Build medication verification card
  Widget _buildMedicationVerificationCard() {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'İlaç bilgileriniz doğru mu?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Current medication name display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medication,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentMedication.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Verification radio buttons
            Text(
              'Bu ilaç adı doğru mu?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Evet'),
                    value: true,
                    groupValue: _isMedicationCorrect,
                    onChanged: (value) {
                      setState(() {
                        _isMedicationCorrect = value;
                        _showCorrectionField = false;
                        _correctionController.clear();
                      });
                      // Evet seçilince geçmişe kaydet
                      _addToHistoryIfCorrect();
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Hayır'),
                    value: false,
                    groupValue: _isMedicationCorrect,
                    onChanged: (value) {
                      setState(() {
                        _isMedicationCorrect = value;
                        _showCorrectionField = true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
            
            // Correction text field
            if (_showCorrectionField) ...[
              const SizedBox(height: 16),
              Text(
                'Ambalaj üzerinde yazan tam ilaç adı:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _correctionController,
                decoration: InputDecoration(
                  hintText: 'Örn: Parol 500mg, Aspirin Cardio 100mg',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit),
                  suffixIcon: IconButton(
                    onPressed: _hasValidCorrectionText ? _submitCorrection : null,
                    icon: const Icon(Icons.send),
                    tooltip: 'Düzelt',
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _submitCorrection();
                  }
                },
                textInputAction: TextInputAction.send,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Add medication to search history if correct
  Future<void> _addToHistoryIfCorrect() async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.addToSearchHistory(_currentMedication.name);
      _showSnackBar('İlaç geçmişe eklendi');
    } catch (e) {
      _showSnackBar('Geçmişe eklerken hata: $e', isError: true);
    }
  }

  // Show info about auto-adding to history
  void _showAutoHistorySnackBar() {
    _showSnackBar('💡 Bilgiler doğruysa "Evet" seçin, otomatik geçmişe eklensin');
  }

  // Check if should auto-add to history on first load
  void _checkInitialHistoryAdd() {
    // İlk açılışta hiçbir radio seçili değilse,
    // kullanıcıya bilgi ver ama otomatik ekleme
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isMedicationCorrect == null) {
        _showSnackBar('💡 Bilgiler doğruysa "Evet" seçerek geçmişe ekleyebilirsiniz');
      }
    });
  }

  // Submit medication name correction
  Future<void> _submitCorrection() async {
    final correctedName = _correctionController.text.trim();
    if (correctedName.isEmpty) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Create a new search request with corrected medication name
      final request = SearchRequest(
        medicationName: correctedName,
        language: appProvider.language,
      );

      final response = await _apiService.searchMedication(request);
      
      if (response.success && response.data != null) {
        setState(() {
          _currentMedication = response.data!;
          _isMedicationCorrect = null;
          _showCorrectionField = false;
          _correctionController.clear();
          _hasValidCorrectionText = false;
        });
        _showSnackBar('İlaç bilgileri güncellendi');
        
        // Yeni ilaç bilgisi getirildikten sonra 
        // user hiçbir radio seçmezse otomatik geçmişe kaydet
        _showAutoHistorySnackBar();
      } else {
        _showSnackBar(response.error ?? 'Düzeltme başarısız', isError: true);
      }
    } catch (e) {
      _showSnackBar('Düzeltme sırasında hata: $e', isError: true);
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
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
            title: Text(_currentMedication.name),
            actions: [
              // Text-to-Speech button
              IconButton(
                onPressed: _ttsService.isSpeaking ? _stopSpeaking : _speakMedicationInfo,
                icon: Icon(
                  _ttsService.isSpeaking ? Icons.stop : Icons.volume_up,
                ),
                tooltip: _ttsService.isSpeaking ? 'Durdurun' : 'Sesli Oku',
              ),
              
              // Feedback button
              IconButton(
                onPressed: _isUpdating ? null : _showFeedbackDialog,
                icon: const Icon(Icons.feedback),
                tooltip: 'Geri Bildirim',
              ),
            ],
          ),
          body: _isUpdating
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Bilgiler güncelleniyor...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Medication name verification
                      _buildMedicationVerificationCard(),
                      
                      const SizedBox(height: 16),
                      
                      // Verification status
                      if (!_currentMedication.isVerified)
                        Card(
                          color: Colors.orange.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bu bilgiler henüz doğrulanmamıştır. Kullanmadan önce doktorunuza danışın.',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Medication information card
                      MedicationInfoCard(medication: _currentMedication),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _ttsService.isSpeaking ? _stopSpeaking : _speakMedicationInfo,
                              icon: Icon(_ttsService.isSpeaking ? Icons.stop : Icons.volume_up),
                              label: Text(_ttsService.isSpeaking ? 'Durdurun' : 'Sesli Oku'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUpdating ? null : _showFeedbackDialog,
                              icon: const Icon(Icons.feedback),
                              label: const Text('Bilgi Hatası Bildir'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Disclaimer
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.blue.shade700,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Önemli Uyarı',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bu uygulama sadece bilgilendirme amaçlıdır. İlaç kullanımından önce mutlaka doktorunuza veya eczacınıza danışın. Kendi kendine tedavi uygulamayın.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.blue.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
