import 'dart:async';

import 'package:fyp_source_code/chat/data/models/message_model.dart';
import 'package:fyp_source_code/services/api_names.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket _socket;
  bool _isInitialized = false;

  final _messageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _flowEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _volunteerLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _trackingStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get flowEventStream =>
      _flowEventController.stream;
  Stream<Map<String, dynamic>> get volunteerLocationStream =>
      _volunteerLocationController.stream;
  Stream<Map<String, dynamic>> get trackingStatusStream =>
      _trackingStatusController.stream;

  bool get isConnected => _isInitialized && _socket.connected;

  /// 🔌 Connect with JWT Token
  void connect(String token) {
    try {
      // If already initialized and connected, just return
      if (_isInitialized && _socket.connected) {
        print('ℹ️ Socket already connected');
        return;
      }

      print('🔌 Connecting to WebSocket...');

      final socketUrl = ApiNames.socketBaseUrl;

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(10)
            .setAuth({'token': token})
            .disableAutoConnect() // optional, but safe
            .build(),
      );

      _isInitialized = true;
      _socket.connect();
      _setupListeners();
    } catch (e) {
      print('❌ Error connecting to WebSocket: $e');
    }
  }

  /// 📡 Listeners
  void _setupListeners() {
    _socket.onConnect((_) {
      print('✅ WebSocket connected');
      _connectionController.add(true);
    });

    _socket.onDisconnect((_) {
      print('❌ WebSocket disconnected');
      _connectionController.add(false);
    });

    _socket.onConnectError((data) {
      print('❌ Connection error: $data');
      _connectionController.add(false);
    });

    _socket.onError((data) {
      print('❌ Socket error: $data');
    });

    // Reconnect event - re-setup listeners when reconnecting
    _socket.onReconnect((_) {
      print('🔄 WebSocket reconnected - re-establishing listeners...');
      _connectionController.add(true);
    });

    // 📩 Receive message
    _socket.on('receive_message', (data) {
      try {
        print('📨 [SOCKET] Message received event: $data');
        final message = Message.fromJson(Map<String, dynamic>.from(data));
        print(
          '📨 [SOCKET] Parsed message - From: ${message.senderId}, Content: ${message.content}',
        );
        _messageController.add(message);
        print('📨 [SOCKET] Added to stream');
      } catch (e) {
        print('❌ Error parsing receive_message: $e');
      }
    });

    // ✔ Message sent confirmation
    _socket.on('message_sent', (data) {
      try {
        print('📤 [SOCKET] Message sent confirmation: $data');
        final message = Message.fromJson(Map<String, dynamic>.from(data));
        _messageController.add(message);
      } catch (e) {
        print('❌ Error parsing message_sent: $e');
      }
    });

    // ✍️ Typing indicator
    _socket.on('user_typing', (data) {
      try {
        _typingController.add(Map<String, dynamic>.from(data));
      } catch (e) {
        print('❌ Error parsing user_typing: $e');
      }
    });

    _listenToFlowEvent('new_help_request');
    _listenToFlowEvent('help_request_accepted');
    _listenToFlowEvent('help_request_resolved');
    _listenToFlowEvent('new_alert');

    _socket.on('volunteer_location', (data) {
      try {
        _volunteerLocationController.add(Map<String, dynamic>.from(data));
      } catch (e) {
        print('Error parsing volunteer_location: $e');
      }
    });

    _socket.on('tracking_status', (data) {
      try {
        _trackingStatusController.add(Map<String, dynamic>.from(data));
      } catch (e) {
        print('Error parsing tracking_status: $e');
      }
    });
  }

  void _listenToFlowEvent(String eventName) {
    _socket.on(eventName, (data) {
      try {
        _flowEventController.add({
          'event': eventName,
          'data': data is Map ? Map<String, dynamic>.from(data) : data,
        });
      } catch (e) {
        print('Error parsing $eventName: $e');
      }
    });
  }

  /// 📤 Send message
  void sendMessage({required String receiverId, required String content}) {
    if (!_isInitialized) {
      print('❌ Socket not initialized');
      return;
    }
    print("📤 Sending: $content → $receiverId");
    _socket.emit('send_message', {
      'receiverId': receiverId,
      'content': content,
    });
  }

  /// ✍️ Emit typing status
  void emitTyping({required String receiverId, required bool isTyping}) {
    if (!_isInitialized) {
      print('❌ Socket not initialized');
      return;
    }
    _socket.emit('typing', {'receiverId': receiverId, 'isTyping': isTyping});
  }

  /// 📚 Request conversation history
  void requestConversation({required String otherUserId, int limit = 50}) {
    if (!_isInitialized) {
      print('❌ Socket not initialized');
      return;
    }
    _socket.emit('get_conversation', {
      'otherUserId': otherUserId,
      'limit': limit,
    });
  }

  void emitStartTracking(String requestId) {
    if (!_isInitialized) return;
    _socket.emit('start_tracking', {'requestId': requestId});
  }

  void emitStopTracking(String requestId) {
    if (!_isInitialized) return;
    _socket.emit('stop_tracking', {'requestId': requestId});
  }

  void emitLocationUpdate({
    required double latitude,
    required double longitude,
    required String requestId,
  }) {
    if (!_isInitialized) return;
    _socket.emit('update_location', {
      'latitude': latitude,
      'longitude': longitude,
      'requestId': requestId,
    });
  }

  /// 🔌 Disconnect gracefully (keeps streams open for reconnection)
  void disconnect() {
    if (!_isInitialized) return;
    print('🔌 Disconnecting gracefully...');
    _socket.disconnect();
    // Don't close controllers - keep them open for reconnection
  }

  /// 🧹 Dispose streams (hard close)
  void dispose() {
    print('🧹 Disposing SocketService...');
    _messageController.close();
    _typingController.close();
    _connectionController.close();
    _flowEventController.close();
    if (_isInitialized) {
      _socket.disconnect();
    }
  }
}
