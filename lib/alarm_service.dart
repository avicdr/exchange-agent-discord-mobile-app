import 'package:flutter/services.dart';

class AlarmService {
  static const _channel = MethodChannel('exchange_sentinel/alarm');
  static Future<void> start({required String title, required String body}) async {
    await _channel.invokeMethod<void>('start', {'title': title, 'body': body});
  }
  static Future<void> stop() => _channel.invokeMethod<void>('stop');
}
