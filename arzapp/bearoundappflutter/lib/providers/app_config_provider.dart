import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import 'package:dio/dio.dart';

class AppConfigProvider extends ChangeNotifier {
  final _apiService = ApiService();
  
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  AppConfigProvider() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Config loading is no longer needed since premium is removed
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadConfig();
  }
}

