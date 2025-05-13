import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/setoran_model.dart';
import 'auth_service.dart';

class SetoranService {
  final AuthService authService;

  SetoranService(this.authService);

  Future<SetoranModel?> getSetoranSaya() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        token = authService.token;
        if (token == null) {
          final success = await authService.refreshToken();
          if (!success) {
            return null;
          }
          token = authService.token;
        }
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mahasiswa/setoran-saya'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['response'] == true && data['data'] != null) {
          return SetoranModel.fromJson(data['data']);
        }
      } else if (response.statusCode == 401) {
        final success = await authService.refreshToken();
        if (success) {
          return getSetoranSaya();
        }
      }
      return null;
    } catch (e) {
      print('Error fetching setoran: $e');
      return null;
    }
  }
}