import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/submission_provider.dart';
import 'package:go_router/go_router.dart';

class SubmissionScreen extends ConsumerStatefulWidget {
  const SubmissionScreen({super.key});

  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> {
  // A map of step index to form keys
  final Map<int, GlobalKey<FormState>> _formKeys = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < SubmissionFormState.totalSteps; i++) {
      _formKeys[i] = GlobalKey<FormState>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligibilityAsync = ref.watch(submissionEligibilityProvider);

    return eligibilityAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (eligibility) {
        if (!eligibility.isEligible) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Submit Idea'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 24),
                    Text(
                      eligibility.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Return to Dashboard'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final state = ref.watch(submissionFormProvider);
        final controller = ref.read(submissionFormProvider.notifier);

        // If success, show completion screen
        if (state.isSuccess) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
                  const SizedBox(height: 24),
                  Text('Submission Successful!', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  const Text('Your idea has been submitted for review.'),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      controller.reset();
                      context.go('/dashboard');
                    },
                    child: const Text('Return to Dashboard'),
                  )
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Submit Idea'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Progress Indicator
                LinearProgressIndicator(
                  value: (state.currentStep + 1) / SubmissionFormState.totalSteps,
                  backgroundColor: Colors.grey.shade200,
                  color: AppTheme.primaryGold,
                  minHeight: 8,
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKeys[state.currentStep],
                      child: _buildCurrentStep(state.currentStep, state.formData, controller),
                    ),
                  ),
                ),

                // Navigation Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                  ),
                  child: Row(
                    children: [
                      if (state.currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.isSubmitting ? null : controller.previousStep,
                            child: const Text('Back'),
                          ),
                        ),
                      if (state.currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () {
                                  if (_formKeys[state.currentStep]?.currentState?.validate() ?? false) {
                                    if (state.currentStep == SubmissionFormState.totalSteps - 1) {
                                      controller.submit();
                                    } else {
                                      controller.nextStep();
                                    }
                                  }
                                },
                          child: state.isSubmitting 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(state.currentStep == SubmissionFormState.totalSteps - 1 ? 'Submit Idea' : 'Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Simplified steps for brevity in this MVP structure
  Widget _buildCurrentStep(int stepIndex, Map<String, dynamic> formData, SubmissionFormController controller) {
    switch (stepIndex) {
      case 0:
        return _buildTextFieldStep(
          title: 'Step 1: The Problem',
          description: 'What specific problem are you addressing?',
          initialValue: formData['problemStatement'],
          onChanged: (val) => controller.updateFormData('problemStatement', val),
          minLines: 4,
          validatorMessage: 'Please describe the problem',
        );
      case 1:
        return _buildTextFieldStep(
          title: 'Step 2: The Idea',
          description: 'What is your proposed solution?',
          initialValue: formData['ideaDescription'],
           onChanged: (val) => controller.updateFormData('ideaDescription', val),
          minLines: 4,
          validatorMessage: 'Please describe your idea',
        );
      case 10:
         // Final Review Step
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text('Final Review', style: Theme.of(context).textTheme.headlineMedium),
             const SizedBox(height: 16),
             Text('Please review your answers before submitting.', style: TextStyle(color: AppTheme.textSecondary)),
             const SizedBox(height: 24),
             Expanded(
               child: ListView(
                 children: [
                   _buildReviewItem('Problem Statement', formData['problemStatement'] ?? 'Not provided'),
                   const SizedBox(height: 16),
                   _buildReviewItem('Idea Description', formData['ideaDescription'] ?? 'Not provided'),
                   // ... list other fields
                 ],
               ),
             )
           ],
         );
      default:
        // Placeholder for steps 3-9
        return _buildTextFieldStep(
          title: 'Step ${stepIndex + 1}',
          description: 'Detail for step ${stepIndex + 1}',
          initialValue: formData['step_$stepIndex'],
          onChanged: (val) => controller.updateFormData('step_$stepIndex', val),
        );
    }
  }

  Widget _buildTextFieldStep({
    required String title,
    required String description,
    String? initialValue,
    required Function(String) onChanged,
    int minLines = 1,
    String? validatorMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(description, style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        const SizedBox(height: 32),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          maxLines: minLines + 2,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (validatorMessage != null && (value == null || value.trim().isEmpty)) {
              return validatorMessage;
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildReviewItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGoldDark)),
        const SizedBox(height: 4),
        Text(value),
        const Divider(height: 24),
      ],
    );
  }
}
