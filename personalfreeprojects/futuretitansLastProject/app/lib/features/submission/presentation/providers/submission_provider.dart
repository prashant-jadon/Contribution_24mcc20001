import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/submission_model.dart';
import '../../data/repositories/submission_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class EligibilityStatus {
  final bool isPaid;
  final bool allModulesCompleted;
  final String message;

  EligibilityStatus(this.isPaid, this.allModulesCompleted, this.message);
  bool get isEligible => isPaid && allModulesCompleted;
}

final submissionEligibilityProvider = FutureProvider<EligibilityStatus>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  final isPaid = user?.isPaid ?? false;

  if (!isPaid) {
    return EligibilityStatus(false, false, 'Please complete payment before submitting your idea.');
  }

  try {
    final authRepo = ref.watch(authRepositoryProvider);
    final completionRes = await authRepo.checkCompletionStatus();
    final allCompleted = completionRes['allCompleted'] == true;
    
    if (!allCompleted) {
      return EligibilityStatus(true, false, 'Complete all learning modules before accessing the final submission form.');
    }
    return EligibilityStatus(true, true, '');
  } catch (e) {
    return EligibilityStatus(true, false, 'Failed to verify module completion status.');
  }
});

final mySubmissionsProvider = FutureProvider<List<SubmissionModel>>((ref) async {
  final repo = ref.watch(submissionRepositoryProvider);
  return repo.getMySubmissions();
});

class SubmissionFormState {
  final int currentStep;
  final Map<String, dynamic> formData;
  final bool isSubmitting;
  final String? error;
  final bool isSuccess;

  // We use 11 steps according to the DB schema/frontend
  static const int totalSteps = 11;

  SubmissionFormState({
    this.currentStep = 0,
    this.formData = const {},
    this.isSubmitting = false,
    this.error,
    this.isSuccess = false,
  });

  SubmissionFormState copyWith({
    int? currentStep,
    Map<String, dynamic>? formData,
    bool? isSubmitting,
    String? error,
    bool? isSuccess,
  }) {
    return SubmissionFormState(
      currentStep: currentStep ?? this.currentStep,
      formData: formData ?? this.formData,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final submissionFormProvider = NotifierProvider<SubmissionFormController, SubmissionFormState>(SubmissionFormController.new);

class SubmissionFormController extends Notifier<SubmissionFormState> {
  late final SubmissionRepository _repository;

  @override
  SubmissionFormState build() {
    _repository = ref.watch(submissionRepositoryProvider);
    return SubmissionFormState();
  }

  void nextStep() {
    if (state.currentStep < SubmissionFormState.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateFormData(String key, dynamic value) {
    final newFormData = Map<String, dynamic>.from(state.formData);
    newFormData[key] = value;
    state = state.copyWith(formData: newFormData);
  }

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final submission = SubmissionModel(
        title: state.formData['projectName'] ?? 'My Idea',
        description: state.formData['problemStatement'] ?? 'Description',
        formData: state.formData,
        status: 'submitted',
      );
      
      await _repository.createSubmission(submission);
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }
  
  void reset() {
    state = SubmissionFormState();
  }
}
