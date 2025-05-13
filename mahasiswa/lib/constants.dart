import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mahasiswa/main.dart';

class Constants {
  // API URLs
  static const String baseUrl = "https://api.tif.uin-suska.ac.id/setoran-dev/v1";
  static const String authUrl = "https://id.tif.uin-suska.ac.id/realms/dev/protocol/openid-connect/token";
  static const String userInfoUrl = "https://id.tif.uin-suska.ac.id/realms/dev/protocol/openid-connect/userinfo";

  // Client credentials
  static String get clientId => dotenv.env['CLIENT_ID'] ?? '';
  static String get clientSecret => dotenv.env['CLIENT_SECRET'] ?? '';

  // Labels
  static const Map<String, String> labelMap = {
    "KP": "Kerja Praktek",
    "SEMKP": "Seminar KP",
    "DAFTAR_TA": "Pendaftaran TA",
    "SEMPRO": "Seminar Proposal",
    "SIDANG_TA": "Sidang TA",
  };

  // Colors
  static const Color primaryColor = Color(0xFF006666);
  static const Color accentColor = Color(0xFFD4AF37);
  static const Color backgroundColor = Color(0xFF008080);
  static const Color cardColor = Color(0xFFF5F5F5);
  static const Color textColor = Color(0xFF333333);
}