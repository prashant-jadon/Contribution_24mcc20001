import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../home/main_navigation.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isLoading = false;
  bool _isLoadingProfile = true;

  // Step 1: Basic Info
  final _nameController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  List<String> _interestedIn = [];

  // Step 2: Interests & Intent
  List<String> _selectedInterests = [];
  String? _relationshipIntent;

  // Step 3: Bio & Prompts
  final _bioController = TextEditingController();
  final _whyOnAppController = TextEditingController();
  final _lookingForController = TextEditingController();

  // Step 4: Location & Work
  final _cityController = TextEditingController();
  final _collegeController = TextEditingController();
  final _workplaceController = TextEditingController();

  // Step 5: Photos
  List<File> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Ensure profile is loaded
      if (authProvider.profile == null && authProvider.isAuthenticated) {
        await authProvider.loadUser();
      }

      final profile = authProvider.profile;
      if (profile != null) {
        // Load existing profile data into form
        _nameController.text = profile.name;
        if (profile.dateOfBirth != null) {
          _dateOfBirth = profile.dateOfBirth;
        }
        _gender = profile.gender;
        // Convert backend interestedIn values to display text
        _interestedIn = profile.interestedIn
            .map((value) => AppConstants.getDisplayInterestedIn(value))
            .whereType<String>()
            .toList();
        _selectedInterests = List<String>.from(profile.interests);
        _relationshipIntent = profile.relationshipIntent;
        _bioController.text = profile.bio ?? '';
        _whyOnAppController.text = profile.whyOnApp ?? '';
        _lookingForController.text = profile.lookingFor ?? '';
        _cityController.text = profile.location?.city ?? '';
        _collegeController.text = profile.college?.name ?? '';
        _workplaceController.text = profile.workplace?.company ?? '';

        debugPrint('Loaded existing profile: isComplete=${profile.isComplete}');
        
        // If profile is already complete, navigate to main screen
        if (profile.isComplete) {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavigation()),
              (route) => false,
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading existing profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _whyOnAppController.dispose();
    _lookingForController.dispose();
    _cityController.dispose();
    _collegeController.dispose();
    _workplaceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickImage() async {
    if (_photos.length >= AppConstants.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${AppConstants.maxPhotos} photos allowed'),
          backgroundColor: AppTheme.statusWarning,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _photos.add(File(pickedFile.path));
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty &&
            _dateOfBirth != null &&
            _gender != null &&
            _interestedIn.isNotEmpty;
      case 1:
        // Require at least 3 interests for 100% profile strength
        return _selectedInterests.length >= 3 && _relationshipIntent != null;
      case 2:
        // Require bio with at least 50 characters for 100% profile strength
        return _bioController.text.trim().length >= 50 &&
            _whyOnAppController.text.trim().isNotEmpty &&
            _lookingForController.text.trim().isNotEmpty;
      case 3:
        return _cityController.text.trim().isNotEmpty;
      case 4:
        // Require at least 1 photo for 100% profile strength
        return _photos.length >= 1;
      default:
        return true;
    }
  }

  String? _getValidationError() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          return 'Please enter your name';
        }
        if (_dateOfBirth == null) {
          return 'Please select your date of birth';
        }
        if (_gender == null) {
          return 'Please select your gender';
        }
        if (_interestedIn.isEmpty) {
          return 'Please select who you are interested in';
        }
        return null;
      case 1:
        if (_selectedInterests.length < 3) {
          return 'Please select at least 3 interests';
        }
        if (_relationshipIntent == null) {
          return 'Please select your relationship intent';
        }
        return null;
      case 2:
        if (_bioController.text.trim().length < 50) {
          return 'Bio must be at least 50 characters';
        }
        if (_whyOnAppController.text.trim().isEmpty) {
          return 'Please tell us why you\'re on the app';
        }
        if (_lookingForController.text.trim().isEmpty) {
          return 'Please tell us what you\'re looking for';
        }
        return null;
      case 3:
        if (_cityController.text.trim().isEmpty) {
          return 'Please enter your city';
        }
        return null;
      case 4:
        if (_photos.isEmpty) {
          return 'Please add at least one photo';
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _submitProfile() async {
    // Validate all required fields for 100% profile completion
    final validationError = _getValidationError();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    // Additional validation
    if (_bioController.text.trim().length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bio must be at least 50 characters for profile completion'),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 3 interests'),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one photo'),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();

      // Validate relationship intent
      final relationshipIntentValue = AppConstants.getRelationshipIntentValue(_relationshipIntent);
      if (relationshipIntentValue == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a valid relationship intent'),
            backgroundColor: AppTheme.statusError,
          ),
        );
        return;
      }

      // Map gender to backend enum value
      final backendGender = AppConstants.getBackendGender(_gender);
      if (backendGender == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a valid gender'),
            backgroundColor: AppTheme.statusError,
          ),
        );
        return;
      }

      // Validate age one more time before submission
      final today = DateTime.now();
      int age = today.year - _dateOfBirth!.year;
      final monthDiff = today.month - _dateOfBirth!.month;
      if (monthDiff < 0 || (monthDiff == 0 && today.day < _dateOfBirth!.day)) {
        age--;
      }
      
      if (age < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be at least 18 years old to use arz'),
            backgroundColor: AppTheme.statusError,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Convert interestedIn display text to backend values
      List<String> backendInterestedIn = [];
      if (_interestedIn.contains('Everyone')) {
        backendInterestedIn = ['everyone'];
      } else {
        for (String option in _interestedIn) {
          final backendValue = AppConstants.getBackendInterestedIn(option);
          if (backendValue != null) {
            backendInterestedIn.add(backendValue);
          }
        }
      }

      if (backendInterestedIn.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select who you are interested in.'),
            backgroundColor: AppTheme.statusError,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Prepare profile data with all required fields for 100% completion
      final profileData = {
        'name': _nameController.text.trim(),
        'dateOfBirth': _dateOfBirth!.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
        'gender': backendGender,
        'interestedIn': backendInterestedIn,
        'relationshipIntent': relationshipIntentValue,
        'bio': _bioController.text.trim(),
        'interests': _selectedInterests.map((i) => i.toLowerCase()).toList(), // Backend expects lowercase
        'whyOnApp': _whyOnAppController.text.trim(),
        'lookingFor': _lookingForController.text.trim(),
        'location': {
          'city': _cityController.text.trim(),
        },
        if (_collegeController.text.isNotEmpty)
          'college': {
            'name': _collegeController.text.trim(),
          },
        if (_workplaceController.text.isNotEmpty)
          'workplace': {
            'company': _workplaceController.text.trim(),
          },
        'visibility': 'discoverable',
      };

      debugPrint('Submitting profile data: $profileData');

      // Step 1: Setup profile
      final success = await authProvider.setupProfile(profileData);

      if (!success) {
        final errorMessage = authProvider.errorMessage ?? 'Failed to setup profile';
        
        // If profile already exists and is complete, load it and navigate
        if (errorMessage.toLowerCase().contains('already exists') || 
            errorMessage.toLowerCase().contains('profile already')) {
          debugPrint('Profile already exists, loading existing profile...');
          await authProvider.loadUser();
          
          if (authProvider.profile != null && 
              authProvider.profile!.isComplete) {
            // Profile is complete, navigate to main screen
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainNavigation()),
                (route) => false,
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppTheme.statusError,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;

      // Step 2: Upload photos (all photos must be uploaded for 100% completion)
      int uploadedCount = 0;
      int failedCount = 0;
      for (final photo in _photos) {
        try {
          final formData = FormData.fromMap({
            'photo': await MultipartFile.fromFile(
              photo.path,
              filename: photo.path.split('/').last,
            ),
          });
          final uploadResponse = await apiService.uploadPhoto(formData);
          if (uploadResponse.statusCode == 200 && uploadResponse.data['success']) {
            uploadedCount++;
            debugPrint('Photo uploaded successfully: $uploadedCount/${_photos.length}');
          } else {
            failedCount++;
            debugPrint('Photo upload failed: ${uploadResponse.data['message']}');
          }
        } catch (e) {
          failedCount++;
          debugPrint('Error uploading photo: $e');
        }
      }

      if (uploadedCount == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photos. Please try again.'),
              backgroundColor: AppTheme.statusError,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Step 3: Reload user to get updated profile with calculated strength
      // Wait a bit for the backend to process the profile
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Try loading user up to 3 times with retries
      bool profileLoaded = false;
      for (int i = 0; i < 3; i++) {
        await authProvider.loadUser();
        if (authProvider.profile != null) {
          profileLoaded = true;
          break;
        }
        if (i < 2) {
          // Wait before retry
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }

      // Step 4: Verify profile is 100% complete before allowing entry
      if (!profileLoaded || authProvider.profile == null) {
        debugPrint('Profile not loaded after retries. Current state: profile=${authProvider.profile}, user=${authProvider.user}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile created but not loaded. Please restart the app or try logging in again.'),
              backgroundColor: AppTheme.statusWarning,
              duration: Duration(seconds: 5),
            ),
          );
          // Still allow navigation if profile was created successfully
          // User can complete profile later
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
            (route) => false,
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final profile = authProvider.profile!;
      if (!profile.isComplete) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete all required fields to continue.'),
              backgroundColor: AppTheme.statusWarning,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Profile is 100% complete, allow entry
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during profile setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while fetching existing profile
    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: _previousStep,
              )
            : null,
        title: Text('Step ${_currentStep + 1} of $_totalSteps'),
        actions: [
          if (_currentStep < _totalSteps - 1)
            TextButton(
              onPressed: _canProceed() ? _nextStep : null,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppTheme.surfaceDark,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildBasicInfoStep(),
                _buildInterestsStep(),
                _buildBioStep(),
                _buildLocationStep(),
                _buildPhotosStep(),
              ],
            ),
          ),
          // Continue button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_canProceed() ? _nextStep : null),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.backgroundDark,
                          ),
                        )
                      : Text(_currentStep == _totalSteps - 1
                          ? 'Complete Profile'
                          : 'Continue'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let\'s get to know you',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            'Tell us a bit about yourself',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 32),

          // Name
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              hintText: 'What should we call you?',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Date of Birth
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 6570)), // ~18 years
                firstDate: DateTime(1950),
                lastDate: DateTime.now().subtract(const Duration(days: 6570)), // Must be 18+
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primary,
                        surface: AppTheme.surfaceDark,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                // Validate age (must be 18+)
                final today = DateTime.now();
                int age = today.year - date.year;
                final monthDiff = today.month - date.month;
                if (monthDiff < 0 || (monthDiff == 0 && today.day < date.day)) {
                  age--;
                }
                
                if (age < 18) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You must be at least 18 years old to use arz'),
                        backgroundColor: AppTheme.statusError,
                      ),
                    );
                  }
                  return;
                }
                
                setState(() {
                  _dateOfBirth = date;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(
                  color: AppTheme.textTertiary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, color: AppTheme.textSecondary),
                  const SizedBox(width: 16),
                  Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Date of Birth',
                    style: TextStyle(
                      color: _dateOfBirth != null
                          ? AppTheme.textPrimary
                          : AppTheme.textTertiary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Gender
          Text(
            'Gender',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppConstants.genders.map((gender) {
              final isSelected = _gender == gender;
              return ChoiceChip(
                label: Text(gender),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _gender = selected ? gender : null;
                  });
                },
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.backgroundDark : AppTheme.textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Interested In
          Text(
            'Interested In',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Who would you like to see?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppConstants.interestedInOptions.map((option) {
              final isSelected = _interestedIn.contains(option);
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      // If "Everyone" is selected, clear others and only select Everyone
                      if (option == 'Everyone') {
                        _interestedIn = ['Everyone'];
                      } else {
                        // Remove "Everyone" if a specific option is selected
                        _interestedIn.remove('Everyone');
                        _interestedIn.add(option);
                      }
                    } else {
                      _interestedIn.remove(option);
                    }
                  });
                },
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.backgroundDark : AppTheme.textPrimary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you into?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least 3 interests (${_selectedInterests.length}/${AppConstants.maxInterests})',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _selectedInterests.length >= 3 
                      ? AppTheme.textSecondary 
                      : AppTheme.statusError,
                ),
          ),
          if (_selectedInterests.length < 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Please select at least 3 interests for profile completion',
                style: TextStyle(
                  color: AppTheme.statusError,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppConstants.availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected &&
                        _selectedInterests.length < AppConstants.maxInterests) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.backgroundDark : AppTheme.textPrimary,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          Text(
            'What are you looking for?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          Column(
            children: AppConstants.relationshipIntents.map((intent) {
              final isSelected = _relationshipIntent == intent;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _relationshipIntent = intent;
                    });
                  },
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          intent,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell your story',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let others know what makes you unique',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 32),

          // Bio
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            maxLength: AppConstants.maxBioLength,
            decoration: InputDecoration(
              labelText: 'Bio',
              hintText: 'Write something interesting about yourself...',
              alignLabelWithHint: true,
              helperText: '${_bioController.text.length}/50 characters minimum',
              helperMaxLines: 1,
              errorText: _bioController.text.isNotEmpty && _bioController.text.length < 50
                  ? 'Bio must be at least 50 characters for profile completion'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Why on app
          TextFormField(
            controller: _whyOnAppController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Why are you on this app?',
              hintText: 'Share your reason for joining...',
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Looking for
          TextFormField(
            controller: _lookingForController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'What are you looking for?',
              hintText: 'Describe your ideal connection...',
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where are you?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help people near you find your profile',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 32),

          // City
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              hintText: 'Enter your city',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // College
          TextFormField(
            controller: _collegeController,
            decoration: const InputDecoration(
              labelText: 'College/University (Optional)',
              hintText: 'Where did you study?',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Workplace
          TextFormField(
            controller: _workplaceController,
            decoration: const InputDecoration(
              labelText: 'Workplace (Optional)',
              hintText: 'Where do you work?',
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add your photos',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add up to ${AppConstants.maxPhotos} photos. First photo is your main profile picture.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 32),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: AppConstants.maxPhotos,
            itemBuilder: (context, index) {
              if (index < _photos.length) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        image: DecorationImage(
                          image: FileImage(_photos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.statusError,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Main',
                            style: TextStyle(
                              color: AppTheme.backgroundDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }

              return GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(
                      color: AppTheme.textTertiary.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


