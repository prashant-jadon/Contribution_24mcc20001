import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _collegeController;
  late TextEditingController _workplaceController;
  List<String> _selectedInterests = [];
  String? _relationshipIntent;
  List<String> _interestedIn = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthProvider>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _cityController = TextEditingController(text: profile?.location?.city ?? '');
    _collegeController = TextEditingController(text: profile?.college?.name ?? '');
    _workplaceController = TextEditingController(text: profile?.workplace?.company ?? '');
    _selectedInterests = List.from(profile?.interests ?? []);
    _relationshipIntent = profile?.relationshipIntent;
    _interestedIn = (profile?.interestedIn ?? [])
        .map((v) => AppConstants.getDisplayInterestedIn(v))
        .whereType<String>()
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _collegeController.dispose();
    _workplaceController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_interestedIn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select who you are interested in'),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.updateProfile({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'interests': _selectedInterests,
        'relationshipIntent': _relationshipIntent,
        'interestedIn': _interestedIn.map((opt) => AppConstants.getBackendInterestedIn(opt)).whereType<String>().toList(),
        'location': {
          'city': _cityController.text.trim(),
        },
        if (_collegeController.text.isNotEmpty)
          'college': {'name': _collegeController.text.trim()},
        if (_workplaceController.text.isNotEmpty)
          'workplace': {'company': _workplaceController.text.trim()},
      });

      if (mounted && response.statusCode == 200) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppTheme.statusSuccess,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
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

  Future<void> _addPhoto() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profile = authProvider.profile;

    if (profile != null && profile.photos.length >= AppConstants.maxPhotos) {
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
        _isLoading = true;
      });

      try {
        final formData = FormData.fromMap({
          'photo': await MultipartFile.fromFile(
            pickedFile.path,
            filename: pickedFile.path.split('/').last,
          ),
        });

        await ApiService().uploadPhoto(formData);
        await authProvider.loadUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded!'),
              backgroundColor: AppTheme.statusSuccess,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading photo: ${e.toString()}'),
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
  }

  Future<void> _deletePhoto(String photoId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService().deletePhoto(photoId);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted'),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting photo: ${e.toString()}'),
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final profile = authProvider.profile;

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Edit Profile'),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Photos Section
                Text(
                  'Photos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (profile?.photos.length ?? 0) + 1,
                    itemBuilder: (context, index) {
                      if (index == (profile?.photos.length ?? 0)) {
                        // Add photo button
                        return GestureDetector(
                          onTap: _addPhoto,
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.textTertiary.withOpacity(0.3),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 32,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final photo = profile!.photos[index];
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: NetworkImage(photo.url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (profile.photos.length > 1)
                            Positioned(
                              top: 8,
                              right: 20,
                              child: GestureDetector(
                                onTap: () => _deletePhoto(photo.id),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusError,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
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
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Main',
                                  style: TextStyle(
                                    color: AppTheme.backgroundDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Basic Info
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: AppConstants.maxBioLength,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell others about yourself...',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _collegeController,
                  decoration: const InputDecoration(
                    labelText: 'College/University',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _workplaceController,
                  decoration: const InputDecoration(
                    labelText: 'Workplace',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                ),

                const SizedBox(height: 32),

                // Interests
                Text(
                  'Interests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected &&
                              _selectedInterests.length <
                                  AppConstants.maxInterests) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.backgroundDark
                            : AppTheme.textPrimary,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Interested In
                Text(
                  'Interested In',
                  style: Theme.of(context).textTheme.titleLarge,
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
                            if (option == 'Everyone') {
                              _interestedIn = ['Everyone'];
                            } else {
                              _interestedIn.remove('Everyone');
                              if (!_interestedIn.contains(option)) {
                                _interestedIn.add(option);
                              }
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

                const SizedBox(height: 32),

                // Relationship Intent
                Text(
                  'Looking for',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
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
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withOpacity(0.1)
                                : AppTheme.surfaceDark,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 16),
                              Text(intent),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

