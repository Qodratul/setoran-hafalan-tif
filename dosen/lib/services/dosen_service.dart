import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/mahasiswa_model.dart';
import '../models/dosen_model.dart';

class DosenService {
  Future<Map<String, dynamic>?> getPASaya() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/dosen/pa-saya'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
    } catch (e) {
      print('Error getting PA data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSetoranMahasiswa(String nim) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/mahasiswa/setoran/$nim'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
    } catch (e) {
      print('Error getting setoran mahasiswa: $e');
      return null;
    }
  }

  Future<bool> simpanSetoran(String nim, List<Map<String, String>> dataSetoran, String? tglSetoran) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

    final Map<String, dynamic> body = {
      'data_setoran': dataSetoran,
    };

    if (tglSetoran != null) {
      body['tgl_setoran'] = tglSetoran;
    }

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/mahasiswa/setoran/$nim'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    return response.statusCode == 200;
    } catch (e) {
      print('Error saving setoran: $e');
      return false;
    }
  }

  Future<bool> deleteSetoran(String nim, List<Map<String, String>> dataSetoran) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('${Constants.baseUrl}/mahasiswa/setoran/$nim'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'data_setoran': dataSetoran,
      }),
    );

    return response.statusCode == 200;
    } catch (e) {
      print('Error deleting setoran: $e');
      return false;
    }
  }
}