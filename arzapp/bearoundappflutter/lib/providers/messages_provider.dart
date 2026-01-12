import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:dio/dio.dart';
import '../core/services/api_service.dart';
import '../core/services/websocket_service.dart';
import '../models/message_model.dart';
import '../models/request_model.dart';

class MessagesProvider extends ChangeNotifier {
  final _apiService = ApiService();
  final _wsService = WebSocketService();

  List<ConversationModel> _conversations = [];
  List<MessageRequestModel> _pendingRequests = [];
  List<MessageRequestModel> _sentRequests = [];
  Map<String, List<MessageModel>> _messages = {};
  RequestStatsModel? _requestStats;

  bool _isLoadingConversations = false;
  bool _isLoadingRequests = false;
  int _unreadCount = 0;
  String? _currentConversationId;

  List<ConversationModel> get conversations => _conversations;
  List<MessageRequestModel> get pendingRequests => _pendingRequests;
  List<MessageRequestModel> get sentRequests => _sentRequests;
  RequestStatsModel? get requestStats => _requestStats;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingRequests => _isLoadingRequests;
  int get unreadCount => _unreadCount;

  List<MessageModel> getMessages(String conversationId) {
    return _messages[conversationId] ?? [];
  }

  void init() {
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    _wsService.onNewMessage = (data) {
      final message = MessageModel.fromJson(data['message']);
      final conversationId = data['conversationId'];

      if (_messages.containsKey(conversationId)) {
        // Check if message already exists (to prevent duplicates from API + WebSocket)
        final existingIndex = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
        if (existingIndex == -1) {
          // Message doesn't exist, add it to the beginning (newest messages go at start)
          // List is stored as [newest, ..., oldest] so reverse: true shows newest at bottom
          _messages[conversationId]!.insert(0, message);
        } else {
          // Message already exists, update it (in case of status changes)
          _messages[conversationId]![existingIndex] = message;
        }
      } else {
        _messages[conversationId] = [message];
      }

      // Update conversation list
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        // Defer to avoid calling during build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          loadConversations(); // Refresh to update last message
        });
      }

      if (_currentConversationId != conversationId) {
        _unreadCount++;
      }

      notifyListeners();
    };

    _wsService.onNewRequest = (data) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        loadPendingRequests();
      });
    };

    _wsService.onRequestAccepted = (data) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        loadConversations();
        loadSentRequests();
      });
    };

    _wsService.onRevealRequested = (data) {
      final conversationId = data['conversationId'];
      debugPrint('Reveal requested for conversation: $conversationId');
      // Reload messages to show the system message
      if (_currentConversationId == conversationId) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          loadMessages(conversationId);
        });
      }
      // Reload conversations to update last message
      SchedulerBinding.instance.addPostFrameCallback((_) {
        loadConversations();
      });
    };

    _wsService.onMessageRead = (data) {
      final conversationId = data['conversationId'];
      final messageIds = List<String>.from(data['messageIds'] ?? []);

      if (_messages.containsKey(conversationId)) {
        for (var i = 0; i < _messages[conversationId]!.length; i++) {
          final msg = _messages[conversationId]![i];
          if (messageIds.contains(msg.id)) {
            // Create new message with isRead = true
            _messages[conversationId]![i] = MessageModel(
              id: msg.id,
              conversationId: msg.conversationId,
              senderId: msg.senderId,
              senderUsername: msg.senderUsername,
              content: msg.content,
              type: msg.type,
              isRead: true,
              readAt: DateTime.now(),
              replyTo: msg.replyTo,
              reactions: msg.reactions,
              isDeleted: msg.isDeleted,
              createdAt: msg.createdAt,
            );
          }
        }
        notifyListeners();
      }
    };
  }

  void _safeNotifyListeners() {
    // Defer notifyListeners to avoid calling during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    _safeNotifyListeners();

    try {
      debugPrint('Loading conversations...');
      final response = await _apiService.getConversations();
      debugPrint('Conversations response status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'];
        if (data is List) {
          _conversations = data.map((c) {
            try {
              return ConversationModel.fromJson(c);
            } catch (e) {
              debugPrint('Error parsing conversation: $e, data: $c');
              return null;
            }
          }).whereType<ConversationModel>().toList();
          debugPrint('Loaded ${_conversations.length} conversations');
        } else {
          debugPrint('Unexpected data format for conversations: ${data.runtimeType}');
          _conversations = [];
        }
      } else {
        debugPrint('Failed to load conversations: ${response.data}');
        _conversations = [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading conversations: $e');
      debugPrint('Stack trace: $stackTrace');
      _conversations = [];
    }

    _isLoadingConversations = false;
    _safeNotifyListeners();
  }

  Future<void> loadPendingRequests() async {
    _isLoadingRequests = true;
    _safeNotifyListeners();

    try {
      debugPrint('Loading pending requests...');
      final response = await _apiService.getPendingRequests();
      debugPrint('Pending requests response status: ${response.statusCode}');
      debugPrint('Pending requests response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'];
        if (data is List) {
          _pendingRequests = data.map((r) {
            try {
              return MessageRequestModel.fromJson(r);
            } catch (e) {
              debugPrint('Error parsing pending request: $e, data: $r');
              return null;
            }
          }).whereType<MessageRequestModel>().toList();
          debugPrint('Loaded ${_pendingRequests.length} pending requests');
        } else {
          debugPrint('Unexpected data format for pending requests: ${data.runtimeType}');
          _pendingRequests = [];
        }
      } else {
        debugPrint('Failed to load pending requests: ${response.data}');
        _pendingRequests = [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading pending requests: $e');
      debugPrint('Stack trace: $stackTrace');
      _pendingRequests = [];
    }

    _isLoadingRequests = false;
    _safeNotifyListeners();
  }

  Future<void> loadSentRequests() async {
    try {
      debugPrint('Loading sent requests...');
      final response = await _apiService.getSentRequests();
      debugPrint('Sent requests response status: ${response.statusCode}');
      debugPrint('Sent requests response success: ${response.data['success']}');
      debugPrint('Sent requests response data type: ${response.data['data'].runtimeType}');
      if (response.data['data'] is List) {
        debugPrint('Sent requests response data length: ${(response.data['data'] as List).length}');
      }
      
      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'];
        if (data is List) {
          debugPrint('Parsing ${data.length} sent requests...');
          _sentRequests = data.map((r) {
            try {
              final parsed = MessageRequestModel.fromJson(r);
              debugPrint('Successfully parsed request: ${parsed.id}, recipient: ${parsed.recipientId}');
              return parsed;
            } catch (e, stackTrace) {
              debugPrint('Error parsing request: $e');
              debugPrint('Stack trace: $stackTrace');
              debugPrint('Request data: $r');
              return null;
            }
          }).whereType<MessageRequestModel>().toList();
          debugPrint('Successfully loaded ${_sentRequests.length} sent requests');
        } else {
          debugPrint('Unexpected data format for sent requests: ${data.runtimeType}, data: $data');
          _sentRequests = [];
        }
        _safeNotifyListeners();
      } else {
        debugPrint('Failed to load sent requests: ${response.data}');
        _sentRequests = [];
        _safeNotifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading sent requests: $e');
      debugPrint('Stack trace: $stackTrace');
      _sentRequests = [];
      _safeNotifyListeners();
    }
  }

  Future<void> loadRequestStats() async {
    try {
      final response = await _apiService.getRequestStats();
      if (response.statusCode == 200 && response.data['success']) {
        _requestStats = RequestStatsModel.fromJson(response.data['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading request stats: $e');
    }
  }

  Future<void> loadMessages(String conversationId) async {
    _currentConversationId = conversationId;

    try {
      final response = await _apiService.getMessages(conversationId);
      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'] as List;
        final messages = data.map((m) => MessageModel.fromJson(m)).toList();
        // Backend sends messages in oldest-first order (after reverse)
        // But we need newest-first for reverse: true ListView to show newest at bottom
        // So we reverse the list here
        _messages[conversationId] = messages.reversed.toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    try {
      final response = await _apiService.sendMessage(conversationId, {
        'content': content,
        'type': 'text',
      });

      if (response.statusCode == 201 && response.data['success']) {
        final message = MessageModel.fromJson(response.data['data']['message']);
        if (_messages.containsKey(conversationId)) {
          // Check if message already exists (might have come via WebSocket first)
          final existingIndex = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
          if (existingIndex == -1) {
            // Message doesn't exist, add it to the beginning (newest messages go at start)
            // List is stored as [newest, ..., oldest] so reverse: true shows newest at bottom
            _messages[conversationId]!.insert(0, message);
          } else {
            // Message already exists (came via WebSocket), update it
            _messages[conversationId]![existingIndex] = message;
          }
        } else {
          _messages[conversationId] = [message];
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  Future<bool> sendMessageRequest({
    required String recipientId,
    required String message,
    required String source,
    bool isAnonymous = true,
  }) async {
    try {
      final response = await _apiService.sendMessageRequest({
        'recipientId': recipientId,
        'message': message,
        'source': source,
        'isAnonymous': isAnonymous,
      });

      if (response.statusCode == 201 && response.data['success']) {
        // Reload sent requests to show the new one
        await loadSentRequests();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending request: $e');
      return false;
    }
  }

  Future<bool> acceptRequest(String requestId) async {
    try {
      final response = await _apiService.acceptRequest(requestId);
      if (response.statusCode == 200 && response.data['success']) {
        _pendingRequests.removeWhere((r) => r.id == requestId);
        loadConversations();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error accepting request: $e');
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    try {
      final response = await _apiService.rejectRequest(requestId);
      if (response.statusCode == 200 && response.data['success']) {
        _pendingRequests.removeWhere((r) => r.id == requestId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      return false;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    try {
      final response = await _apiService.cancelRequest(requestId);
      if (response.statusCode == 200 && response.data['success']) {
        _sentRequests.removeWhere((r) => r.id == requestId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error cancelling request: $e');
      return false;
    }
  }

  Future<bool> requestReveal(String conversationId) async {
    try {
      final response = await _apiService.requestReveal(conversationId);
      if (response.statusCode == 200 && response.data['success']) {
        // Reload messages to show the system message
        if (_currentConversationId == conversationId) {
          await loadMessages(conversationId);
        }
        // Reload conversations to update the last message
        await loadConversations();
        return true;
      }
      debugPrint('Request reveal failed: ${response.statusCode}, ${response.data}');
      return false;
    } on DioException catch (e) {
      debugPrint('Error requesting reveal: ${e.response?.statusCode}');
      debugPrint('Error data: ${e.response?.data}');
      if (e.response?.data != null) {
        final message = e.response?.data['message'] ?? 'Failed to request reveal';
        debugPrint('Backend error message: $message');
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected error requesting reveal: $e');
      return false;
    }
  }

  Future<bool> revealIdentity(String conversationId, {List<String>? fields}) async {
    try {
      final response = await _apiService.revealIdentity(conversationId, fields: fields);
      if (response.statusCode == 200 && response.data['success']) {
        // Reload conversations to get updated reveal status
        await loadConversations();
        // Also reload the specific conversation if it's currently being viewed
        if (_currentConversationId == conversationId) {
          await loadMessages(conversationId);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error revealing identity: $e');
      return false;
    }
  }

  void joinConversation(String conversationId) {
    _wsService.joinConversation(conversationId);
    _currentConversationId = conversationId;
  }

  void leaveConversation(String conversationId) {
    _wsService.leaveConversation(conversationId);
    _currentConversationId = null;
  }

  void startTyping(String conversationId) {
    _wsService.startTyping(conversationId);
  }

  void stopTyping(String conversationId) {
    _wsService.stopTyping(conversationId);
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiService.getUnreadCount();
      if (response.statusCode == 200 && response.data['success']) {
        _unreadCount = response.data['data']['unreadCount'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }
}

