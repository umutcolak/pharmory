import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AccessibilityControls extends StatelessWidget {
  const AccessibilityControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Font size control
                Row(
                  children: [
                    const Icon(Icons.text_fields),
                    const SizedBox(width: 8),
                    const Text('Yazı Boyutu:'),
                    const Spacer(),
                    Text('${appProvider.fontSize.round()}'),
                  ],
                ),
                Slider(
                  value: appProvider.fontSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 6,
                  label: '${appProvider.fontSize.round()}',
                  onChanged: (value) {
                    appProvider.updateFontSize(value);
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Language selection
                Row(
                  children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 8),
                    const Text('Dil:'),
                    const Spacer(),
                    DropdownButton<String>(
                      value: appProvider.language,
                      items: const [
                        DropdownMenuItem(
                          value: 'tr',
                          child: Text('Türkçe'),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          appProvider.updateLanguage(value);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
