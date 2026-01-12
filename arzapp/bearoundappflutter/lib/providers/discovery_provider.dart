import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/profile_model.dart';

class DiscoveryProvider extends ChangeNotifier {
  final _apiService = ApiService();

  List<ProfileModel> _profiles = [];
  List<ProfileModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;

  // Filters
  int? _ageMin;
  int? _ageMax;
  String? _gender;
  String? _city;
  String? _college;

  List<ProfileModel> get profiles => _profiles;
  List<ProfileModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  int? get ageMin => _ageMin;
  int? get ageMax => _ageMax;
  String? get gender => _gender;
  String? get city => _city;
  String? get college => _college;
  bool get hasActiveFilters =>
      _ageMin != null || _ageMax != null || _gender != null || _city != null || _college != null;

  Future<void> loadDiscoveryFeed() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': 1,
        'limit': 10,
        if (_ageMin != null) 'ageMin': _ageMin,
        if (_ageMax != null) 'ageMax': _ageMax,
        if (_gender != null) 'gender': _gender,
        if (_city != null) 'city': _city,
        if (_college != null) 'college': _college,
      };

      final response = await _apiService.getDiscoveryFeed(queryParams);

      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'];
        final profilesList = data['profiles'] as List?;

        if (profilesList != null) {
          _profiles = profilesList
              .map((p) {
                try {
                  final profile = ProfileModel.fromJson(p);
                  debugPrint('Loaded profile: ${profile.name}, photos: ${profile.photos.length}');
                  return profile;
                } catch (e, stackTrace) {
                  debugPrint('Error parsing profile: $e');
                  debugPrint('Stack trace: $stackTrace');
                  debugPrint('Profile data: $p');
                  return null;
                }
              })
              .whereType<ProfileModel>()
              .toList();
        } else {
          _profiles = [];
        }

      } else {
        _errorMessage = response.data['message'] ?? 'Failed to load profiles';
      }
    } catch (e) {
      _errorMessage = 'Error loading profiles';
      debugPrint('Discovery error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> skipProfile(String profileId) async {
    try {
      await _apiService.skipProfile(profileId);
      _profiles.removeWhere((p) => p.id == profileId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error skipping profile: $e');
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final response = await _apiService.searchUsers({
        'q': query,
        'page': 1,
        'limit': 20,
        if (_ageMin != null) 'ageMin': _ageMin,
        if (_ageMax != null) 'ageMax': _ageMax,
        if (_city != null) 'city': _city,
        if (_college != null) 'college': _college,
      });

      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'] as List;
        _searchResults = data.map((p) => ProfileModel.fromJson(p)).toList();
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }

    _isSearching = false;
    notifyListeners();
  }

  void setFilters({
    int? ageMin,
    int? ageMax,
    String? gender,
    String? city,
    String? college,
  }) {
    _ageMin = ageMin;
    _ageMax = ageMax;
    _gender = gender;
    _city = city;
    _college = college;
    notifyListeners();
  }

  /// Set default "show me" filter based on user's interestedIn preferences.
  /// If interestedIn contains 'everyone' or multiple values, we show all (gender=null).
  /// If it contains a single gender, we set gender filter to that.
  void setDefaultShowMeFromProfile(ProfileModel? profile) {
    if (profile == null) return;
    final prefs = profile.interestedIn;
    if (prefs.isEmpty || prefs.contains('everyone') || prefs.length > 1) {
      _gender = null;
    } else {
      // Only one preference
      _gender = prefs.first;
    }
    notifyListeners();
  }

  void clearFilters() {
    _ageMin = null;
    _ageMax = null;
    _gender = null;
    _city = null;
    _college = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  void removeProfile(String profileId) {
    _profiles.removeWhere((p) => p.id == profileId);
    notifyListeners();
  }
}

