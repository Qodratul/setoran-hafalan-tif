import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {
  // API URLs
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get authUrl => dotenv.env['AUTH_URL'] ?? '';
  static String get userInfoUrl => dotenv.env['USER_INFO_URL'] ?? '';

  // Client credentials
  static String get clientId => dotenv.env['CLIENT_ID'] ?? '';
  static String get clientSecret => dotenv.env['CLIENT_SECRET'] ?? '';

  // Labels

  // Colors
  static const Color primaryColor = Color(0xFF006666);
  static const Color accentColor = Color(0xFFD4AF37);
  static const Color backgroundColor = Color(0xFF008080);
  static const Color cardColor = Color(0xFFF5F5F5);
  static const Color textColor = Color(0xFF333333);
}