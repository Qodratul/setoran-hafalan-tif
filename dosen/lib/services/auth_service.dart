import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../widgets/auth_dialog.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _idToken;
  bool _isLoading = false;
  DateTime? _tokenExpiry;
  DateTime? _refreshTokenExpiry;
  bool _isDosen = false;

  Timer? _tokenCheckTimer;
  bool _isCheckingToken = false;
  bool _dialogShown = false;

  BuildContext? _context;

  bool get isAuthenticated => _token != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!);
  bool get isLoading => _isLoading;
  String? get token => _token;
  bool get isDosen => _isDosen;

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
    _tokenCheckTimer?.cancel();
    _tokenCheckTimer = null;
  }

  Future<void> _autoCheckTokenStatus() async {
    if (_isCheckingToken || _context == null || !isAuthenticated || _dialogShown) {
      return;
    }

    try {
      _isCheckingToken = true;
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
      if (kDebugMode) {
        print('Error during auto token check: $e');
      }
    } finally {
      _isCheckingToken = false;
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
        _refreshTokenExpiry = DateTime.now().add(Duration(seconds: data['refresh_expires_in']));

        final isDosen = await _verifyDosen();

        if (!isDosen) {
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
        await prefs.setString('refreshTokenExpiry', _refreshTokenExpiry!.toIso8601String());
        await prefs.setBool('isDosen', true);

        _isDosen = true;
        notifyListeners();

        return true;
      } else {
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

  Future<bool> _verifyDosen() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/dosen/pa-saya'),
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
      print('Verify Dosen error: $e');
      return false;
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

    _isDosen = prefs.getBool('isDosen') ?? false;
    notifyListeners();
  }

  Future<bool> handleTokenRefresh({bool showDialog = true}) async {
    if (_refreshTokenExpiry == null || DateTime.now().isAfter(_refreshTokenExpiry!)) {
      if (_context != null && showDialog) {
        if (Navigator.of(_context!).canPop()) {
          Navigator.of(_context!).pop();
        }
        await AuthDialogs.showSessionExpiredDialog(_context!, canRefresh: false);
      }
      await logout();
      return false;
    }

    if (isTokenExpired) {
      if (_context != null && showDialog) {
        if (Navigator.of(_context!).canPop()) {
          Navigator.of(_context!).pop();
        }
        bool shouldRefresh = await AuthDialogs.showTokenExpiredDialog(_context!);
        if (shouldRefresh) {
          return await _performTokenRefresh();
        } else {
          await logout();
          return false;
        }
      }
      return await _performTokenRefresh();
    }

    if (willExpireSoon) {
      if (_context != null && showDialog) {
        if (Navigator.of(_context!).canPop()) {
          Navigator.of(_context!).pop();
        }
        bool shouldRefresh = await AuthDialogs.showSessionExpiredDialog(_context!, canRefresh: true);
        if (shouldRefresh) {
          return await _performTokenRefresh();
        } else {
          return false;
        }
      }
    }
    return true;
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
      _updateTokens(data);

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error performing token refresh: $e');
      }

      if (_context != null) {
        if (Navigator.of(_context!).canPop()) {
          Navigator.of(_context!).pop();
        }
        await AuthDialogs.showSessionExpiredDialog(_context!, canRefresh: false);
      }
      await logout();
      return false;
    }
  }

  void _updateTokens(Map<String, dynamic> data) {
    _token = data['access_token'];
    _refreshToken = data['refresh_token'];
    _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));

    _refreshTokenExpiry = DateTime.now().add(Duration(seconds: data['refresh_expires_in']));

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('token', _token!);
      prefs.setString('refreshToken', _refreshToken!);
      prefs.setString('tokenExpiry', _tokenExpiry!.toIso8601String());
      prefs.setString('refreshTokenExpiry', _refreshTokenExpiry!.toIso8601String());
    });
  }

  Future<bool> refreshToken() async {
    return await _performTokenRefresh();
  }

  Future<bool> ensureValidToken({bool showDialog = true}) async {
    if (isTokenExpired || willExpireSoon) {
      return await handleTokenRefresh(showDialog: showDialog);
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
      await prefs.remove('refreshTokenExpiry');
      await prefs.remove('isDosen');

      _token = null;
      _refreshToken = null;
      _idToken = null;
      _tokenExpiry = null;
      _refreshTokenExpiry = null;
      _isDosen = false;
      notifyListeners();

      if (_context != null) {
        Navigator.of(_context!).popUntil((route) => route.isFirst);
        Navigator.of(_context!).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _stopTokenCheckTimer();
    super.dispose();
  }
}