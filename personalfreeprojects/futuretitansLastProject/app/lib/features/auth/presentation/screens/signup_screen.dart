import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolSlugController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Custom Step Tracking
  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _schoolSlugController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate current step before proceeding
    bool isValid = false;
    if (_currentStep == 0) {
      if (_nameController.text.isNotEmpty && _emailController.text.contains('@') && _phoneController.text.isNotEmpty) {
        isValid = true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all personal details correctly')));
      }
    } else if (_currentStep == 1) {
      if (_schoolController.text.isNotEmpty && _cityController.text.isNotEmpty && _countryController.text.isNotEmpty) {
        isValid = true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required education fields')));
      }
    }

    if (isValid) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      await ref.read(authControllerProvider.notifier).signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        school: _schoolController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        schoolSlug: _schoolSlugController.text.trim().isNotEmpty
            ? _schoolSlugController.text.trim()
            : null,
      );
      // Navigation is handled automatically by GoRouter's redirect
      // when authControllerProvider state changes to authenticated
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        cursorColor: AppTheme.primaryGold,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
          prefixIcon: Icon(icon, color: AppTheme.primaryGoldLight),
          suffixIcon: suffixIcon,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primaryGold),
          ),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.2),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Step 1 of 3: Personal Profile', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'John Doe',
          icon: Icons.person_outline,
        ),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'john@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '+1 234 567 8900',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Step 2 of 3: Education Details', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _schoolController,
          label: 'School / Institution',
          hint: 'Future Academy',
          icon: Icons.school_outlined,
        ),
        _buildTextField(
          controller: _schoolSlugController,
          label: 'School Slug (Optional)',
          hint: 'e.g. future-academy',
          icon: Icons.tag,
        ),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _cityController,
                label: 'City',
                hint: 'New York',
                icon: Icons.location_city_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _countryController,
                label: 'Country',
                hint: 'USA',
                icon: Icons.public_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Step 3 of 3: Security', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscureText: !_showPassword,
          suffixIcon: IconButton(
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          validator: (v) {
            if (v == null || v.length < 6) return 'Must be at least 6 characters';
            return null;
          },
        ),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscureText: !_showConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
            onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
          ),
          validator: (v) {
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _previousStep,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Logo/Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.05),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]
                    ),
                    child: Text(
                      'FUTURE TITANS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryGold,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Join us and start your innovation journey',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Error Message
                if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Dynamic Form Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _currentStep == 0 
                      ? _buildStep0() 
                      : _currentStep == 1 
                        ? _buildStep1() 
                        : _buildStep2(),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Navigation Controls
                Row(
                  children: [
                    // Progress Indicators
                    Expanded(
                      child: Row(
                        children: List.generate(_totalSteps, (index) {
                          final isActive = index <= _currentStep;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primaryGold : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: isActive ? [BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.5), blurRadius: 4)] : [],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 32),
                    
                    // Main Action Button
                    Container(
                      width: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryGold, AppTheme.primaryGoldDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: ElevatedButton(
                        onPressed: authState.status == AuthStatus.loading 
                          ? null 
                          : (_currentStep < _totalSteps - 1 ? _nextStep : _submit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: authState.status == AuthStatus.loading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentStep < _totalSteps - 1 ? 'Next Step' : 'Launch', 
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                                  ),
                                  if (_currentStep < _totalSteps - 1) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward, size: 16, color: Colors.white)
                                  ]
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Log In', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
