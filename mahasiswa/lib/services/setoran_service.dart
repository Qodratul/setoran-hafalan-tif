// lib/services/setoran_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../constants.dart';
import '../models/setoran_model.dart';
import 'auth_service.dart';

class SetoranService {
  final AuthService authService;

  SetoranService(this.authService);

  Future<SetoranModel?> getSetoranSaya() async {
    try {
      final hasValidToken = await authService.ensureValidToken();
      if (!hasValidToken) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token') ?? authService.token;

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
        final success = await authService.handleTokenRefresh();
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

  Future<Map<String, dynamic>> downloadKartuMurajaah() async {
    try {
      final hasValidToken = await authService.ensureValidToken(showDialog: true);
      if (!hasValidToken) {
        return {
          'success': false,
          'error': 'Sesi tidak valid atau user membatalkan perpanjangan sesi',
          'errorCode': 'SESSION_INVALID'
        };
      }

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token') ?? authService.token;

      if (token == null) {
        return {
          'success': false,
          'error': 'Token tidak tersedia',
          'errorCode': 'TOKEN_UNAVAILABLE'
        };
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mahasiswa/kartu-murojaah-saya'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
          'Content-Type': 'application/json',
        },
      );

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/pdf')) {
        print('Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
      }

      if (response.statusCode == 200) {
        if (!contentType.contains('application/pdf')) {
          print('Warning: Response is not PDF format. Content-Type: $contentType');
          return {
            'success': false,
            'error': 'Server tidak mengembalikan file PDF',
            'errorCode': 'INVALID_FORMAT'
          };
        }

        final bytes = response.bodyBytes;
        print('PDF size: ${bytes.length} bytes');

        if (bytes.isEmpty) {
          print('Error: Empty PDF file received');
          return {
            'success': false,
            'error': 'File PDF kosong',
            'errorCode': 'EMPTY_FILE'
          };
        }

        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'kartu_murajaah_$timestamp.pdf';
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(bytes);

        if (await file.exists()) {
          final fileSize = await file.length();
          print('File saved successfully: $filePath (${fileSize} bytes)');

          await prefs.setString('kartuMurajaahPath', filePath);
          await prefs.setString('kartuMurajaahFileName', fileName);

          return {
            'success': true,
            'filePath': filePath,
            'fileName': fileName,
            'fileSize': fileSize
          };
        } else {
          return {
            'success': false,
            'error': 'Gagal menyimpan file',
            'errorCode': 'SAVE_FAILED'
          };
        }

      } else if (response.statusCode == 401) {
        print('Token expired during request, attempting to refresh...');
        final success = await authService.handleTokenRefresh(showDialog: true);
        if (success) {
          return downloadKartuMurajaah();
        } else {
          return {
            'success': false,
            'error': 'Token expired dan user membatalkan refresh atau refresh gagal',
            'errorCode': 'TOKEN_REFRESH_FAILED'
          };
        }
      } else if (response.statusCode == 403) {
        String errorMessage = 'Akses ditolak';
        String errorCode = 'ACCESS_DENIED';

        try {
          if (contentType.contains('application/json')) {
            final errorData = json.decode(response.body);
            if (errorData['error_description'] != null) {
              switch (errorData['error_description']) {
                case 'not_authorized':
                  errorMessage = 'Anda tidak memiliki akses untuk mengunduh kartu murajaah. Pastikan Anda sudah melakukan setoran atau hubungi admin.';
                  errorCode = 'NOT_AUTHORIZED';
                  break;
                case 'insufficient_scope':
                  errorMessage = 'Token tidak memiliki scope yang diperlukan';
                  errorCode = 'INSUFFICIENT_SCOPE';
                  break;
                default:
                  errorMessage = 'Akses ditolak: ${errorData['error_description']}';
              }
            }
          } else if (contentType.contains('text/html')) {
            errorMessage = 'Akses ditolak oleh server. Kemungkinan Anda belum memiliki setoran yang divalidasi atau belum memiliki akses ke kartu murajaah.';
            errorCode = 'HTML_FORBIDDEN';
          } else {
            if (response.body.isNotEmpty && response.body.length < 1000) {
              errorMessage = 'Akses ditolak: ${response.body}';
            }
          }
        } catch (e) {
          errorMessage = 'Akses ditolak. Kemungkinan Anda belum memiliki setoran yang divalidasi.';
        }

        return {
          'success': false,
          'error': errorMessage,
          'errorCode': errorCode,
          'statusCode': 403
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Kartu murajaah tidak ditemukan. Mungkin belum ada setoran yang divalidasi.',
          'errorCode': 'NOT_FOUND',
          'statusCode': 404
        };
      } else {
        String errorMessage = 'Terjadi kesalahan server (${response.statusCode})';

        try {
          if (contentType.contains('application/json')) {
            final errorData = json.decode(response.body);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          }
        } catch (e) {
          print('Failed to parse error response: $e');
        }

        return {
          'success': false,
          'error': errorMessage,
          'errorCode': 'HTTP_ERROR',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('Error downloading kartu murajaah: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan: $e',
        'errorCode': 'EXCEPTION'
      };
    }
  }

  Future<Map<String, dynamic>> checkKartuMurajaahAccess() async {
    try {
      final hasValidToken = await authService.ensureValidToken(showDialog: false);
      if (!hasValidToken) {
        return {'hasAccess': false, 'reason': 'Token tidak valid'};
      }

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token') ?? authService.token;

      if (token == null) {
        return {'hasAccess': false, 'reason': 'Token tidak tersedia'};
      }

      final response = await http.head(
        Uri.parse('${Constants.baseUrl}/mahasiswa/kartu-murojaah-saya'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 401) {
        final refreshSuccess = await authService.handleTokenRefresh(showDialog: true);
        if (refreshSuccess) {
          return checkKartuMurajaahAccess();
        }
      }

      return {
        'hasAccess': response.statusCode == 200,
        'statusCode': response.statusCode,
        'headers': response.headers,
        'reason': response.statusCode == 403 ? 'Akses ditolak' :
        response.statusCode == 404 ? 'Kartu tidak ditemukan' :
        response.statusCode == 401 ? 'Token tidak valid' : null
      };
    } catch (e) {
      return {'hasAccess': false, 'reason': 'Error: $e'};
    }
  }

  @deprecated
  Future<bool> kartuMurajaah() async {
    final result = await downloadKartuMurajaah();
    return result['success'] ?? false;
  }
}