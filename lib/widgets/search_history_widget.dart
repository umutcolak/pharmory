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

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.history),
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
          ),
          
          // History list
          Expanded(
            child: ListView.separated(
              itemCount: searchHistory.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final searchTerm = searchHistory[index];
                return ListTile(
                  leading: const Icon(Icons.medication),
                  title: Text(searchTerm),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => onSearchTap(searchTerm),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
