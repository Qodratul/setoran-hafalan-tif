// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _idToken;
  bool _isLoading = false;
  DateTime? _tokenExpiry;
  bool _isMahasiswa = false;

  Timer? _tokenCheckTimer;
  bool _isCheckingToken = false;
  bool _dialogShown = false;

  BuildContext? _context;

  bool get isAuthenticated => _token != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!);
  bool get isLoading => _isLoading;
  String? get token => _token;
  bool get isMahasiswa => _isMahasiswa;

  void setContext(BuildContext context) {
    _context = context;
    _startTokenCheckTimer();
  }

  void clearContext() {
    _context = null;
    _stopTokenCheckTimer();
    _dialogShown = false;
  }

  bool get willExpireSoon {
    if (_tokenExpiry == null) return false;
    final now = DateTime.now();
    final fiveMinutesFromNow = now.add(const Duration(minutes: 5));
    return _tokenExpiry!.isBefore(fiveMinutesFromNow);
  }

  bool get isTokenExpired {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  void _startTokenCheckTimer() {
    _stopTokenCheckTimer();

    _tokenCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _autoCheckTokenStatus();
    });
  }

  void _stopTokenCheckTimer() {
    if (_tokenCheckTimer != null) {
      _tokenCheckTimer!.cancel();
      _tokenCheckTimer = null;
    }
  }

  Future<void> _autoCheckTokenStatus() async {
    if (_isCheckingToken || _context == null || !isAuthenticated || _dialogShown) {
      return;
    }

    try {
      if (isTokenExpired) {
        _dialogShown = true;
        await handleTokenRefresh(showDialog: true);
        _dialogShown = false;
      } else if (willExpireSoon) {
        _dialogShown = true;
        await handleTokenRefresh(showDialog: true);
        _dialogShown = false;
      }
    } catch (e) {
      _dialogShown = false;
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(Constants.authUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': Constants.clientId,
          'client_secret': Constants.clientSecret,
          'grant_type': 'password',
          'username': username,
          'password': password,
          'scope': 'openid profile email',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        _refreshToken = data['refresh_token'];
        _idToken = data['id_token'];

        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));

        final isMahasiswa = await _verifyMahasiswa();

        if (!isMahasiswa) {
          _token = null;
          _refreshToken = null;
          _idToken = null;
          _tokenExpiry = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('refreshToken', _refreshToken!);
        await prefs.setString('idToken', _idToken!);
        await prefs.setString('tokenExpiry', _tokenExpiry!.toIso8601String());
        await prefs.setBool('isMahasiswa', true);

        _isMahasiswa = true;
        _isLoading = false;
        notifyListeners();

        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _verifyMahasiswa() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/mahasiswa/setoran-saya'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] == true && data['data'] != null;
      }
      return false;
    } catch (e) {
      print('Verify Mahasiswa error: $e');
      return false;
    }
  }

  Future<void> loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refreshToken');
    _idToken = prefs.getString('idToken');
    String? expiryString = prefs.getString('tokenExpiry');
    if (expiryString != null) {
      _tokenExpiry = DateTime.parse(expiryString);
    }
    _isMahasiswa = prefs.getBool('isMahasiswa') ?? false;
    notifyListeners();
  }

  Future<bool> handleTokenRefresh({bool showDialog = true}) async {
    if (_refreshToken == null) {
      if (showDialog && _context != null) {
        await _showSessionExpiredDialog(canRefresh: false);
      }
      return false;
    }

    if (showDialog && _context != null) {
      final shouldRefresh = await _showSessionExpiredDialog(canRefresh: true);
      if (!shouldRefresh) {
        await logout();
        return false;
      }
    }

    return await _performTokenRefresh();
  }

  Future<bool> _performTokenRefresh() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final oldRefreshToken = _refreshToken ?? prefs.getString('refreshToken');

      if (oldRefreshToken == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse(Constants.authUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': Constants.clientId,
          'client_secret': Constants.clientSecret,
          'grant_type': 'refresh_token',
          'refresh_token': oldRefreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        _refreshToken = data['refresh_token'];
        _idToken = data['id_token'];

        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));

        await prefs.setString('token', _token!);
        await prefs.setString('refreshToken', _refreshToken!);
        await prefs.setString('idToken', _idToken!);
        await prefs.setString('tokenExpiry', _tokenExpiry!.toIso8601String());

        _isLoading = false;
        notifyListeners();

        if (_context != null) {
          ScaffoldMessenger.of(_context!).showSnackBar(
            const SnackBar(
              content: Text('Sesi berhasil diperpanjang'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        return true;
      } else {
        _isLoading = false;
        notifyListeners();

        if (_context != null) {
          await _showSessionExpiredDialog(canRefresh: false);
        }
        return false;
      }
    } catch (e) {
      print('Token refresh error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _showSessionExpiredDialog({required bool canRefresh}) async {
    if (_context == null) return false;

    return await showDialog<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                canRefresh ? Icons.access_time : Icons.error_outline,
                color: canRefresh ? Colors.orange : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                canRefresh ? 'Sesi Akan Berakhir' : 'Sesi Berakhir',
                style: TextStyle(
                  color: canRefresh ? Colors.orange : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canRefresh
                    ? 'Sesi login Anda akan segera berakhir.'
                    : 'Sesi login Anda telah berakhir.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (canRefresh) ...[
                const Text(
                  'Apakah Anda ingin memperpanjang sesi?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pilih "Ya" untuk melanjutkan atau "Tidak" untuk logout.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'Silakan login kembali untuk melanjutkan.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          actions: [
            if (canRefresh) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                child: const Text('Tidak'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya, Perpanjang'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login Ulang'),
              ),
            ],
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> refreshToken() async {
    return await _performTokenRefresh();
  }

  Future<bool> ensureValidToken({bool showDialog = true}) async {
    if (isTokenExpired) {
      return await handleTokenRefresh(showDialog: showDialog);
    } else if (willExpireSoon && showDialog) {
      return await handleTokenRefresh(showDialog: true);
    }
    return true;
  }

  Future<void> logout() async {
    _stopTokenCheckTimer();

    try {
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('idToken');

      if (idToken != null) {
        await http.post(
          Uri.parse('${Constants.authUrl.split('/token')[0]}/logout'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'client_id': Constants.clientId,
            'client_secret': Constants.clientSecret,
            'id_token_hint': idToken,
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('refreshToken');
      await prefs.remove('idToken');
      await prefs.remove('tokenExpiry');
      await prefs.remove('isMahasiswa');

      _token = null;
      _refreshToken = null;
      _idToken = null;
      _tokenExpiry = null;
      _isMahasiswa = false;
      notifyListeners();

      if (_context != null) {
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _stopTokenCheckTimer();
    super.dispose();
  }
}