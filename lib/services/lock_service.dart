import 'package:flutter/services.dart';

class LockService {
  static const _channel = MethodChannel('com.kathrina.deskstand/lock');

  static Future<void> startLock() async {
    try {
      await _channel.invokeMethod<void>('startLock');
    } on MissingPluginException {
      // Widget tests run without the Android host channel.
    }
  }

  static Future<void> stopLock() async {
    try {
      await _channel.invokeMethod<void>('stopLock');
    } on MissingPluginException {
      // Widget tests run without the Android host channel.
    }
  }
}