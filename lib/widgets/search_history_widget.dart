import 'package:flutter/material.dart';

class SearchHistoryWidget extends StatelessWidget {
  final List<String> searchHistory;
  final Function(String) onSearchTap;
  final VoidCallback onClearHistory;

  const SearchHistoryWidget({
    super.key,
    required this.searchHistory,
    required this.onSearchTap,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (searchHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.history, size: 20),
            const SizedBox(width: 8),
            Text(
              'Son Aramalar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Geçmişi Temizle'),
                    content: const Text('Tüm arama geçmişini silmek istediğinizden emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onClearHistory();
                        },
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Temizle'),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Horizontal scrolling chips
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: searchHistory.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final searchTerm = searchHistory[index];
              return ActionChip(
                avatar: const Icon(Icons.medication, size: 18),
                label: Text(
                  searchTerm,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onPressed: () => onSearchTap(searchTerm),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
