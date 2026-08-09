import 'dart:async';

import 'package:fyp_source_code/chat/data/models/message_model.dart';
import 'package:fyp_source_code/services/api_names.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket _socket;
  bool _isInitialized = false;
  String? _connectedToken;

  final _messageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _flowEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _volunteerLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _trackingStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Replay buffer: last N flow events so new subscribers don't miss
  /// events that arrived between socket connect and listener attach.
  static const int _flowEventBufferMax = 20;
  final List<Map<String, dynamic>> _flowEventBuffer = [];

  /// Replay buffer for volunteer location events.
  static const int _volLocationBufferMax = 10;
  final List<Map<String, dynamic>> _volLocationBuffer = [];

  Stream<Message> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get flowEventStream =>
      _flowEventController.stream;
  Stream<Map<String, dynamic>> get volunteerLocationStream =>
      _volunteerLocationController.stream;
  Stream<Map<String, dynamic>> get trackingStatusStream =>
      _trackingStatusController.stream;

  /// Returns buffered flow events so callers can catch up after subscribing.
  List<Map<String, dynamic>> getBufferedFlowEvents() =>
      List.unmodifiable(_flowEventBuffer);

  /// Returns buffered volunteer location events for replay.
  List<Map<String, dynamic>> getBufferedVolLocations() =>
      List.unmodifiable(_volLocationBuffer);

  bool get isConnected => _isInitialized && _socket.connected;

  /// 🔌 Connect with JWT Token
  ///
  /// Safe to call repeatedly:
  /// - already connected with the same token → no-op
  /// - same token but disconnected → reconnects the live socket
  /// - different token (e.g. after logout/login as another user) → tears
  ///   down the stale socket and registers the new identity server-side
  void connect(String token) {
    try {
      if (_isInitialized && _socket.connected && _connectedToken == token) {
        print('[SOCKET] already connected (same token) - no-op');
        return;
      }

      if (_isInitialized && _connectedToken == token) {
        print('[SOCKET] reconnecting: socket exists but disconnected (same token)');
        _socket.connect();
        return;
      }

      if (_isInitialized) {
        // Token changed: drop the stale socket so the server unregisters
        // the old user before we register the new one.
        print('[SOCKET] token changed - tearing down stale socket');
        try {
          _socket.dispose();
        } catch (_) {}
        _isInitialized = false;
        _connectedToken = null;
      }

      print('[SOCKET] initializing socket: ${ApiNames.socketBaseUrl}');

      final socketUrl = ApiNames.socketBaseUrl;

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            // Practically unlimited: a slow cold start on the server must
            // never permanently kill the real-time channel.
            .setReconnectionAttempts(100000)
            .setAuth({'token': token})
            .disableAutoConnect() // optional, but safe
            .build(),
      );

      _connectedToken = token;
      _isInitialized = true;
      // Attach all socket listeners BEFORE initiating the connection so no
      // server-pushed event (tracking, SOS, chat) can arrive before the
      // corresponding Dart handler is registered.
      _setupListeners();
      _socket.connect();
    } catch (e) {
      print('❌ Error connecting to WebSocket: $e');
    }
  }

  /// 📡 Listeners
  void _setupListeners() {
    _socket.onConnect((_) {
      print('[SOCKET] connected - socket id: ${_socket.id}');
      _connectionController.add(true);
    });

    _socket.onDisconnect((_) {
      print('[SOCKET] disconnected');
      _connectionController.add(false);
    });

    _socket.onConnectError((data) {
      print('[SOCKET] connection error: $data');
      _connectionController.add(false);
    });

    _socket.onError((data) {
      print('[SOCKET] socket error: $data');
    });

    // Reconnect event - re-register flow listeners so the server
    // re-adds this socket to its connectedUsers map (which is wiped
    // on disconnect). Without this, live requests are silently dropped.
    _socket.onReconnect((_) {
      print('[SOCKET] reconnected - re-registering flow listeners');
      _listenToFlowEvent('new_help_request');
      _listenToFlowEvent('help_request_accepted');
      _listenToFlowEvent('help_request_resolved');
      _listenToFlowEvent('new_alert');
      _listenToFlowEvent('sos_escalated');
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
    _listenToFlowEvent('sos_escalated');

    // ✔ Server-side registration acknowledgement (chat.gateway)
    _socket.on('connection_success', (data) {
      final userId = data is Map ? data['userId'] : null;
      final role = StorageHelper().readData('role');
      print(
        '[SOCKET] register event received: connection_success (userId: $userId, role: $role)',
      );
    });

    _socket.on('volunteer_location', (data) {
      try {
        final event = Map<String, dynamic>.from(data);
        _volunteerLocationController.add(event);
        _volLocationBuffer.add(event);
        if (_volLocationBuffer.length > _volLocationBufferMax) {
          _volLocationBuffer.removeAt(0);
        }
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
    _socket.off(eventName);
    _socket.on(eventName, (data) {
      try {
        final payload =
            data is Map ? Map<String, dynamic>.from(data) : null;
        if (eventName == 'new_help_request') {
          final isSos =
              payload != null &&
              (payload['isSos'] == true || payload['escalated'] == true);
          print(
            '[SOCKET] notification received: event=$eventName id=${payload?['_id']} isSos=$isSos',
          );
        } else {
          print('[SOCKET] notification received: event=$eventName');
        }
        final event = {
          'event': eventName,
          'data': payload ?? data,
        };
        _flowEventController.add(event);
        // Buffer for replay so new subscribers don't miss early events
        _flowEventBuffer.add(event);
        if (_flowEventBuffer.length > _flowEventBufferMax) {
          _flowEventBuffer.removeAt(0);
        }
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
    print('[SOCKET] disconnecting gracefully');
    _socket.disconnect();
    // Don't close controllers - keep them open for reconnection
  }

  /// 🧹 Dispose streams (hard close)
  void dispose() {
    print('[SOCKET] disposing SocketService');
    _messageController.close();
    _typingController.close();
    _connectionController.close();
    _flowEventController.close();
    if (_isInitialized) {
      _socket.disconnect();
    }
  }
}
