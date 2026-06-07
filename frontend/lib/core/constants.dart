import 'dart:io';
import 'package:flutter/foundation.dart';

class Constants {
  // Replace with actual IP or domain when deploying to a real server.
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }
}
