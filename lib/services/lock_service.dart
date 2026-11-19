import 'package:flutter/services.dart';

class LockService {
  static const _channel = MethodChannel('com.kathrina.deskstand/lock');

  static Future<void> startLock() async {
    await _channel.invokeMethod<void>('startLock');
  }

  static Future<void> stopLock() async {
    await _channel.invokeMethod<void>('stopLock');
  }
}