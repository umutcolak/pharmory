import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationInfoCard extends StatelessWidget {
  final Medication medication;

  const MedicationInfoCard({
    super.key,
    required this.medication,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medication name
                Row(
                  children: [
                    const Icon(Icons.medication, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        medication.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                
                if (medication.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    medication.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Usage information
        _buildInfoCard(
          context,
          'Kullanım Amacı',
          medication.usage,
          Icons.info,
          Colors.blue,
        ),
        
        // Dosage information
        _buildInfoCard(
          context,
          'Dozaj Bilgisi',
          medication.dosage,
          Icons.schedule,
          Colors.green,
        ),
        
        // Indications
        if (medication.indications.isNotEmpty)
          _buildListCard(
            context,
            'Endikasyonlar',
            medication.indications,
            Icons.check_circle,
            Colors.teal,
          ),
        
        // Side effects
        if (medication.sideEffects.isNotEmpty)
          _buildListCard(
            context,
            'Yan Etkiler',
            medication.sideEffects,
            Icons.warning,
            Colors.orange,
          ),
        
        // Warnings
        if (medication.warnings.isNotEmpty)
          _buildListCard(
            context,
            'Uyarılar',
            medication.warnings,
            Icons.error,
            Colors.red,
          ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
