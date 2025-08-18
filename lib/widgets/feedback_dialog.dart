import 'package:flutter/material.dart';
import '../models/medication.dart';

class FeedbackDialog extends StatefulWidget {
  final Medication medication;
  final Function(String feedbackType, String? additionalInfo) onFeedbackSubmitted;

  const FeedbackDialog({
    super.key,
    required this.medication,
    required this.onFeedbackSubmitted,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  String? _selectedFeedbackType;
  final TextEditingController _additionalInfoController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _feedbackTypes = {
    'incorrect': 'Bilgiler yanlış',
    'incomplete': 'Bilgiler eksik',
    'outdated': 'Bilgiler güncel değil',
    'other': 'Diğer',
  };

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_selectedFeedbackType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir geri bildirim türü seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onFeedbackSubmitted(
        _selectedFeedbackType!,
        _additionalInfoController.text.trim().isEmpty 
            ? null 
            : _additionalInfoController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geri bildiriminiz gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bilgi Hatası Bildir'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.medication.name} ilacı hakkındaki bilgilerde bir sorun mu var?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Sorun türü:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            
            const SizedBox(height: 8),
            
            // Feedback type selection
            ..._feedbackTypes.entries.map((entry) => RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: _selectedFeedbackType,
              onChanged: (value) {
                setState(() {
                  _selectedFeedbackType = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            )),
            
            const SizedBox(height: 16),
            
            // Additional information
            Text(
              'Ek bilgi (isteğe bağlı):',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            
            const SizedBox(height: 8),
            
            TextField(
              controller: _additionalInfoController,
              decoration: const InputDecoration(
                hintText: 'Sorunu daha detaylı açıklayın...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gönder'),
        ),
      ],
    );
  }
}
