import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/api_endpoints.dart';
import '../../providers/app_providers.dart';

class WebSocketService {
  final Ref ref;
  WebSocketChannel? _channel;
  bool _isConnected = false;

  WebSocketService(this.ref);

  void connect(String userId, BuildContext context) {
    if (_isConnected) return;

    final wsUrl = AppEndpoints.baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsUrl/api/v1/notifications/ws/$userId');

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _channel!.stream.listen(
        (message) async {
          final data = jsonDecode(message);
          
          // Mainkan suara notifikasi
          try {
            final player = AudioPlayer();
            await player.play(AssetSource('sounds/notification.mp3'));
          } catch (e) {
            print('Error playing audio: $e');
          }

          // Tampilkan Snackbar Notifikasi
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Notifikasi Baru',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(data['body'] ?? ''),
                  ],
                ),
                backgroundColor: Colors.blue.shade800,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Tutup',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }

          // Refresh data di Riverpod
          ref.invalidate(mySeleksiProvider);
          ref.invalidate(myPengajuanProvider);
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadCountProvider);
        },
        onDone: () {
          _isConnected = false;
        },
        onError: (error) {
          _isConnected = false;
        },
      );
    } catch (e) {
      _isConnected = false;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
}

// Provider untuk WebSocket
final websocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref);
});
