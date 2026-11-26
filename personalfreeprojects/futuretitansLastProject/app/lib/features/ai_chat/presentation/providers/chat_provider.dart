import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class ChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isCompleted;
  final bool isModuleCompleted;
  final Map<String, dynamic>? ssiScore;
  final String? error;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.isCompleted = false,
    this.isModuleCompleted = false,
    this.ssiScore,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isCompleted,
    bool? isModuleCompleted,
    Map<String, dynamic>? ssiScore,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      isModuleCompleted: isModuleCompleted ?? this.isModuleCompleted,
      ssiScore: ssiScore ?? this.ssiScore,
      error: error, // Can set error to null on new copy
    );
  }
}

final chatControllerProvider = NotifierProvider.autoDispose<ChatController, ChatState>(ChatController.new);

class ChatController extends Notifier<ChatState> {
  late final ChatRepository _repository;
  String? _moduleId;
  String? _chapterId;
  bool _initialized = false;

  @override
  ChatState build() {
    _repository = ref.watch(chatRepositoryProvider);
    return ChatState(messages: [], isLoading: true);
  }

  void init(String moduleId, String chapterId) {
    if (_initialized) return;
    _moduleId = moduleId;
    _chapterId = chapterId;
    _initialized = true;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _repository.getChatHistory(_moduleId!, _chapterId!);
      
      // Auto seed if empty
      if (history.conversation.isEmpty && !history.isCompleted) {
        state = state.copyWith(isLoading: true);
        await _repository.sendMessage(_moduleId!, _chapterId!, '__AUTO_SURGE_START__');
        final seededHistory = await _repository.getChatHistory(_moduleId!, _chapterId!);
        
        state = ChatState(
          messages: seededHistory.conversation,
          isCompleted: seededHistory.isCompleted,
          ssiScore: seededHistory.ssiScore,
          isLoading: false,
        );
      } else {
        state = ChatState(
          messages: history.conversation,
          isCompleted: history.isCompleted,
          ssiScore: history.ssiScore,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isCompleted) return;

    final userMessage = ChatMessageModel(
      role: 'user',
      message: text,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _repository.sendMessage(_moduleId!, _chapterId!, text);
      
      final aiMessage = ChatMessageModel(
        role: 'assistant',
        message: response['aiMessage'] ?? '...',
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        ssiScore: response['ssiScore'] ?? state.ssiScore,
        isLoading: false,
      );
    } catch (e) {
      final errorMessage = ChatMessageModel(
        role: 'assistant',
        message: 'Request failed. Please try again.',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  Future<bool> finishChapter() async {
    if (state.isCompleted) return true;
    
    state = state.copyWith(isLoading: true);
    try {
      final res = await _repository.finishChapter(_moduleId!, _chapterId!);

      bool moduleDone = false;
      try {
        final authRepo = ref.read(authRepositoryProvider);
        final completionStatus = await authRepo.checkCompletionStatus();
        final details = completionStatus['details'] as List?;
        if (details != null) {
          final currentMod = details.firstWhere((d) => d['moduleId'] == _moduleId, orElse: () => null);
          if (currentMod != null && currentMod['isComplete'] == true) {
            moduleDone = true;
          }
        }
      } catch (e) {
        // ignore
      }

      state = state.copyWith(
        isCompleted: true,
        isModuleCompleted: moduleDone,
        isLoading: false,
        ssiScore: res['finalSSI'] ?? state.ssiScore,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
