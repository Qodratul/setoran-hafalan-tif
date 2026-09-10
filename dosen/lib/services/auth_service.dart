import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/alert_dialog.dart';
import '../constants.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _idToken;
  bool _isLoading = false;
  DateTime? _tokenExpiry;
  DateTime? _refreshTokenExpiry;

  BuildContext? _context;

  bool get isAuthenticated => _token != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!);
  bool get isLoading => _isLoading;
  String? get token => _token;

  void setContext(BuildContext context) {
    _context = context;
  }

  void clearContext() {
    _context = null;
  }

  Map<String, dynamic>? decodeToken(String token) {
    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding token: $e');
      }
      return null;
    }
  }

  bool isDosenRole(String? token) {
    if (token == null) return false;
    final decoded = decodeToken(token);
    if (decoded == null) return false;
    final roles = List<String>.from(decoded['realm_access']?['roles'] ?? []);
    return roles.contains('dosen');
  }

  Future<bool> login(String username, String password, {BuildContext? context}) async {
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

      if (response.statusCode >= 500 && response.statusCode < 600) {
        if (context != null && context.mounted) {
          ReusableDialog.showErrorDialog(
            context: context,
            title: 'Error',
            message: 'Terjadi kesalahan pada server',
          );
        }
        _token = null;
        _refreshToken = null;
        _idToken = null;
        _tokenExpiry = null;
        _refreshTokenExpiry = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? receivedToken = data['access_token'];
        String? receivedRefreshToken = data['refresh_token'];
        String? receivedIdToken = data['id_token'];
        DateTime? receivedTokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        DateTime? receivedRefreshTokenExpiry = DateTime.now().add(Duration(seconds: data['refresh_expires_in']));

        if (!isDosenRole(receivedToken)) {
          if (context != null && context.mounted) {
            ReusableDialog.showErrorDialog(
              context: context,
              title: 'Akses Ditolak',
              message: 'Anda tidak memiliki akses sebagai dosen',
            );
            if (kDebugMode) {
              debugPrint('Login failed: User does not have "dosen" role.');
            }
          }

          _token = null;
          _refreshToken = null;
          _idToken = null;
          _tokenExpiry = null;
          _refreshTokenExpiry = null;
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _token = receivedToken;
        _refreshToken = receivedRefreshToken;
        _idToken = receivedIdToken;
        _tokenExpiry = receivedTokenExpiry;
        _refreshTokenExpiry = receivedRefreshTokenExpiry;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('refreshToken', _refreshToken!);
        await prefs.setString('idToken', _idToken!);
        await prefs.setString('tokenExpiry', _tokenExpiry!.toIso8601String());
        await prefs.setString('refreshTokenExpiry', _refreshTokenExpiry!.toIso8601String());

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('Login API failed with status: ${response.statusCode}, body: ${response.body}');
        }
        _token = null;
        _refreshToken = null;
        _idToken = null;
        _tokenExpiry = null;
        _refreshTokenExpiry = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refreshToken');
    _idToken = prefs.getString('idToken');
    String? expiryString = prefs.getString('tokenExpiry');
    String? refreshExpiryString = prefs.getString('refreshTokenExpiry');

    if (expiryString != null) {
      _tokenExpiry = DateTime.parse(expiryString);
    }
    if (refreshExpiryString != null) {
      _refreshTokenExpiry = DateTime.parse(refreshExpiryString);
    }

    if (_token != null && !isDosenRole(_token)) {
      await logout();
    }
    notifyListeners();
  }

  Future<bool> handleTokenRefresh() async {
    if (_refreshTokenExpiry == null || DateTime.now().isAfter(_refreshTokenExpiry!)) {
      await logout();
      return false;
    }
    return await _performTokenRefresh();
  }

  Future<bool> _performTokenRefresh() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse(Constants.authUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': Constants.clientId,
          'client_secret': Constants.clientSecret,
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Refresh token failed');
      }

      final data = json.decode(response.body);
      String? refreshedToken = data['access_token'];

      if (!isDosenRole(refreshedToken)) {
        if (kDebugMode) {
          print('Token refresh successful, but user no longer has "dosen" role. Forcing logout.');
        }
        await logout();
        return false;
      }

      await _updateTokens(data);

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error performing token refresh: $e');
      }
      await logout();
      return false;
    }
  }

  Future<void> _updateTokens(Map<String, dynamic> data) async {
    _token = data['access_token'];
    _refreshToken = data['refresh_token'];
    _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));

    if (data.containsKey('refresh_expires_in')) {
      _refreshTokenExpiry = DateTime.now().add(Duration(seconds: data['refresh_expires_in']));
    } else {
      _refreshTokenExpiry = null;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('refreshToken', _refreshToken!);
    await prefs.setString('tokenExpiry', _tokenExpiry!.toIso8601String());
    if (_refreshTokenExpiry != null) {
      await prefs.setString('refreshTokenExpiry', _refreshTokenExpiry!.toIso8601String());
    } else {
      await prefs.remove('refreshTokenExpiry');
    }
  }

  Future<bool> refreshToken() async {
    return await _performTokenRefresh();
  }

  Future<bool> ensureValidToken() async {
    return await handleTokenRefresh();
  }

  Future<void> logout() async {
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
      await prefs.remove('refreshTokenExpiry');

      _token = null;
      _refreshToken = null;
      _idToken = null;
      _tokenExpiry = null;
      _refreshTokenExpiry = null;
      notifyListeners();

      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).popUntil((route) => route.isFirst);
        Navigator.of(_context!).pushReplacementNamed('/login');
      }
    }
  }


}