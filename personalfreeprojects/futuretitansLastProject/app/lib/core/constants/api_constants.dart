class ApiConstants {
  static String get baseUrl {
    return 'https://future-titans-backend-sigma.vercel.app';
  }

  // Auth Endpoints
  static const String login = '/api/auth/login';
  static const String signup = '/api/auth/signup';
  static const String refresh = '/api/auth/refresh';
  static const String profile = '/api/auth/profile';
  static const String updateProfile = '/api/auth/profile'; // PUT
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String checkCompletion = '/api/auth/completion-status';
  
  // Modules Endpoints — backend: GET /api/modules, GET /api/modules/:id
  static const String modules = '/api/modules';
  
  // Chat Endpoints — backend: /api/chat/:moduleId/chapters/:chapterId/...
  static const String chatBase = '/api/chat';
  // Build paths: $chatBase/$moduleId/chapters/$chapterId/history|message|finish
  static const String globalChatMessage = '/api/chat/global/message';
  static const String globalChatHistory = '/api/chat/global/history';

  // Submission Endpoints
  static const String submissions = '/api/submission';
  static const String saveDraft = '/api/submission/draft';
  
  // Payment Endpoints — one-time payment
  static const String paymentInitiate = '/api/payment/initiate';
  static const String paymentVerify = '/api/payment/verify';
  static const String paymentStatus = '/api/payment/status';
  
  // Achievements
  static const String achievements = '/api/achievements';
}
