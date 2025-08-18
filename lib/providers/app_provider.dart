import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  // Font size for accessibility
  double _fontSize = 16.0;
  double get fontSize => _fontSize;

  // Language setting
  String _language = 'tr';
  String get language => _language;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Search history
  List<String> _searchHistory = [];
  List<String> get searchHistory => _searchHistory;

  AppProvider() {
    _loadPreferences();
  }

  // Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _language = prefs.getString('language') ?? 'tr';
    _searchHistory = prefs.getStringList('searchHistory') ?? [];
    notifyListeners();
  }

  // Update font size
  Future<void> updateFontSize(double newSize) async {
    _fontSize = newSize;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', newSize);
    notifyListeners();
  }

  // Update language
  Future<void> updateLanguage(String newLanguage) async {
    _language = newLanguage;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLanguage);
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Add to search history
  Future<void> addToSearchHistory(String searchTerm) async {
    if (!_searchHistory.contains(searchTerm)) {
      _searchHistory.insert(0, searchTerm);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('searchHistory', _searchHistory);
      notifyListeners();
    }
  }

  // Clear search history
  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('searchHistory');
    notifyListeners();
  }
}
