import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _idToken;
  bool _isLoading = false;
  DateTime? _tokenExpiry;
  bool _isDosen = false;

  bool get isAuthenticated => _token != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!);
  bool get isLoading => _isLoading;
  String? get token => _token;
  bool get isDosen => _isDosen;

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
        await prefs.setBool('isDosen', true);

        _isDosen = true;
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
      print('Verify dosen error: $e');
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
    _isDosen = prefs.getBool('isDosen') ?? false;
    notifyListeners();
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
      await prefs.remove('isDosen');

      _token = null;
      _refreshToken = null;
      _idToken = null;
      _tokenExpiry = null;
      _isDosen = false;
      notifyListeners();
    }
  }

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldRefreshToken = prefs.getString('refreshToken');

      if (oldRefreshToken == null) {
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

        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}