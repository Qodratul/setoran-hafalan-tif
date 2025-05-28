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

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get token => _token;

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

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('refreshToken', _refreshToken!);
        await prefs.setString('idToken', _idToken!);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
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

        await prefs.setString('token', _token!);
        await prefs.setString('refreshToken', _refreshToken!);
        await prefs.setString('idToken', _idToken!);

        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refreshToken');
    _idToken = prefs.getString('idToken');
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

      _token = null;
      _refreshToken = null;
      _idToken = null;
      notifyListeners();
    }
  }
}