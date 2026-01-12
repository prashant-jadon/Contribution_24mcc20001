import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  final _storage = const FlutterSecureStorage();

  bool get isConnected => _socket?.connected ?? false;

  // Callbacks
  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onTyping;
  Function(Map<String, dynamic>)? onStopTyping;
  Function(Map<String, dynamic>)? onMessageRead;
  Function(Map<String, dynamic>)? onMessageDelivered;
  Function(Map<String, dynamic>)? onNewRequest;
  Function(Map<String, dynamic>)? onRequestAccepted;
  Function(Map<String, dynamic>)? onIdentityRevealed;
  Function(Map<String, dynamic>)? onRevealRequested;
  Function(Map<String, dynamic>)? onUserOnlineStatus;

  Future<void> connect() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return;

    try {
      _socket = IO.io(
        AppConstants.wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Add polling fallback
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(3)
            .setReconnectionDelay(1000)
            .build(),
      );

      _socket!.onConnect((_) {
        print('✅ WebSocket connected');
      });

      _socket!.onDisconnect((_) {
        print('⚠️ WebSocket disconnected');
      });

      _socket!.onError((error) {
        // WebSocket errors are expected on serverless (Vercel doesn't support WebSockets)
        // Don't show error to user, just log it
        print('⚠️ WebSocket error (expected on serverless): $error');
        // The app will continue to work with HTTP polling via REST API
      });

      _socket!.onConnectError((error) {
        print('⚠️ WebSocket connection error (expected on serverless): $error');
        // Connection will fail on Vercel - this is normal
        // Real-time features will be disabled, but app still works
      });
    } catch (e) {
      print('⚠️ WebSocket initialization error (expected on serverless): $e');
      // Continue without WebSocket - app will use HTTP polling
    }

    // Listen to events
    _socket!.on('new_message', (data) {
      onNewMessage?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('user_typing', (data) {
      onTyping?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('user_stopped_typing', (data) {
      onStopTyping?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('messages_read', (data) {
      onMessageRead?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('messages_delivered', (data) {
      onMessageDelivered?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('new_request', (data) {
      onNewRequest?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('request_accepted', (data) {
      onRequestAccepted?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('identity_revealed', (data) {
      onIdentityRevealed?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('reveal_requested', (data) {
      onRevealRequested?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('online_status_update', (data) {
      onUserOnlineStatus?.call(Map<String, dynamic>.from(data));
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', conversationId);
  }

  void sendMessage(String conversationId, String content, {String? replyTo}) {
    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
      if (replyTo != null) 'replyTo': replyTo,
    });
  }

  void startTyping(String conversationId) {
    _socket?.emit('typing_start', conversationId);
  }

  void stopTyping(String conversationId) {
    _socket?.emit('typing_stop', conversationId);
  }

  void markRead(String conversationId, List<String> messageIds) {
    _socket?.emit('mark_read', {
      'conversationId': conversationId,
      'messageIds': messageIds,
    });
  }

  void getOnlineStatus(List<String> userIds) {
    _socket?.emit('get_online_status', userIds);
  }

  void addReaction(String messageId, String emoji) {
    _socket?.emit('add_reaction', {
      'messageId': messageId,
      'emoji': emoji,
    });
  }
}

