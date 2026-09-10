import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../constants.dart';
import 'auth_service.dart'; // Import AuthService
import 'package:flutter/material.dart';
import '../widgets/alert_dialog.dart';

class DosenService {
  final AuthService _authService;
  BuildContext? _context;

  DosenService(this._authService);

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<dynamic> makeHttpRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    bool isFileDownload = false,
    String? filePrefix,
    String? identifier,
  }) async {
    var result = await _performRequest(endpoint, method, body, isFileDownload, filePrefix, identifier);

    if (result == 'UNAUTHORIZED') {
      bool refreshed = await _authService.ensureValidToken();
      if (refreshed) {
        result = await _performRequest(endpoint, method, body, isFileDownload, filePrefix, identifier);
      } else {
        return null;
      }
    }
    return result;
  }

  Future<dynamic> _performRequest(
      String endpoint,
      String method,
      Map<String, dynamic>? body,
      bool isFileDownload,
      String? filePrefix,
      String? identifier,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || !_authService.isDosenRole(token)) {
        await _authService.logout();
        return null;
      }

      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'apikey': Constants.appKey,
        'Accept': 'application/json',
      };

      if (body != null && !isFileDownload) {
        headers['Content-Type'] = 'application/json';
      }

      final String baseUrl = Constants.baseUrl.endsWith('/')
          ? Constants.baseUrl.substring(0, Constants.baseUrl.length - 1)
          : Constants.baseUrl;
      final String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final uri = Uri.parse('$baseUrl$cleanEndpoint');

      http.Response response;

      debugPrint("Request URL: $uri");
      debugPrint("Request Headers: $headers");
      debugPrint("apikey:${Constants.appKey}");
      if (body != null) {
        debugPrint("Request Body: ${json.encode(body)}");
      }

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      debugPrint('HTTP Response status: ${response.statusCode}');

      if (isFileDownload && response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final fileName = '${filePrefix ?? 'file'}_${identifier ?? DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (isFileDownload) {
          return null;
        }

        if (method.toUpperCase() == 'POST' || method.toUpperCase() == 'DELETE') {
          return true;
        }

        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        return 'UNAUTHORIZED';
      } else if (response.statusCode == 403) {
        debugPrint('HTTP 403 Forbidden: Access denied for endpoint $endpoint');
        if (_context != null && _context!.mounted) {
          ReusableDialog.showErrorDialog(
            context: _context!,
            title: 'Akses Ditolak',
            message: 'Anda tidak memiliki izin untuk mengakses sumber daya ini.',
          );
        }
        return null;
      } else if (response.statusCode >= 500 && response.statusCode < 600) {
        debugPrint('HTTP ${response.statusCode} Server Error: ${response.body}');
        String errorMessage = 'Terjadi kesalahan pada server (${response.statusCode}). Mohon coba lagi nanti.';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          } else if (errorData is Map && errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          }
        } catch (_) {}

        if (_context != null && _context!.mounted) {
          ReusableDialog.showErrorDialog(
            context: _context!,
            title: 'Kesalahan Server',
            message: errorMessage,
          );
        }
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('Error in makeHttpRequest: $e');
      if (_context != null && _context!.mounted) {
        ReusableDialog.showErrorDialog(
          context: _context!,
          title: 'Kesalahan Jaringan',
          message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPASaya() async {
    return await makeHttpRequest(
      endpoint: '/dosen/pa-saya',
      method: 'GET',
    );
  }

  Future<Map<String, dynamic>?> getSetoranMahasiswa(String nim) async {
    return await makeHttpRequest(
      endpoint: '/mahasiswa/setoran/$nim',
      method: 'GET',
    );
  }

  Future<bool> simpanSetoran(String nim, List<Map<String, String>> dataSetoran, String? tglSetoran) async {
    final Map<String, dynamic> body = {
      'data_setoran': dataSetoran,
    };

    if (tglSetoran != null) {
      body['tgl_setoran'] = tglSetoran;
    }

    final result = await makeHttpRequest(
      endpoint: '/mahasiswa/setoran/$nim',
      method: 'POST',
      body: body,
    );

    return result == true;
  }

  Future<bool> deleteSetoran(String nim, List<Map<String, String>> dataSetoran) async {
    final result = await makeHttpRequest(
      endpoint: '/mahasiswa/setoran/$nim',
      method: 'DELETE',
      body: {
        'data_setoran': dataSetoran,
      },
    );

    return result == true;
  }

  Future<String?> getKartuMurojaahMahasiswaPdf(String nim) async {
    return await makeHttpRequest(
      endpoint: '/mahasiswa/kartu-murojaah/$nim',
      method: 'GET',
      isFileDownload: true,
      filePrefix: 'kartu_murojaah',
      identifier: nim,
    );
  }
}