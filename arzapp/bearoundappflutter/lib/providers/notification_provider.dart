import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final _apiService = ApiService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
      }

      final response = await _apiService.getNotifications(
        page: _currentPage,
        limit: _pageSize,
      );

      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'] as List;
        final pagination = response.data['pagination'] ?? {};

        final newNotifications = data
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        if (refresh) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }

        _unreadCount = pagination['unreadCount'] ?? 0;
        _hasMore = newNotifications.length == _pageSize;
        _currentPage++;

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiService.getUnreadNotificationCount();
      if (response.statusCode == 200 && response.data['success']) {
        _unreadCount = response.data['data']['unreadCount'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.markNotificationAsRead(notificationId);
      if (response.statusCode == 200 && response.data['success']) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: _notifications[index].id,
            type: _notifications[index].type,
            title: _notifications[index].title,
            message: _notifications[index].message,
            data: _notifications[index].data,
            relatedUserId: _notifications[index].relatedUserId,
            relatedUsername: _notifications[index].relatedUsername,
            relatedUserPhoto: _notifications[index].relatedUserPhoto,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: _notifications[index].createdAt,
          );
          if (_unreadCount > 0) {
            _unreadCount--;
          }
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.markAllNotificationsRead();
      if (response.statusCode == 200 && response.data['success']) {
        _notifications = _notifications.map((n) {
          return NotificationModel(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            data: n.data,
            relatedUserId: n.relatedUserId,
            relatedUsername: n.relatedUsername,
            relatedUserPhoto: n.relatedUserPhoto,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
          );
        }).toList();
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.deleteNotification(notificationId);
      if (response.statusCode == 200 && response.data['success']) {
        _notifications.removeWhere((n) => n.id == notificationId);
        if (_unreadCount > 0) {
          _unreadCount--;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }
}

