import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('https://id.tif.uin-suska.ac.id/realms/dev/protocol/openid-connect/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'}, // HARUS ganti ke form-urlencoded
      body: {
        'grant_type': 'password',
        'client_secret': 'aqJp3xnXKudgC7RMOshEQP7ZoVKWzoSl',
        'client_id': 'setoran-mobile-dev',
        'username': usernameController.text,
        'password': passwordController.text,
      },
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];
      final idToken = data['id_token'];
      final prefs = await SharedPreferences.getInstance();

      // Simpan token
      await prefs.setString('token', accessToken);

      // Decode untuk ambil nama dan email
      Map<String, dynamic> decodedToken = JwtDecoder.decode(idToken);
      String nama = decodedToken['name'];
      String email = decodedToken['email'];

      // Simpan ke SharedPreferences juga (jika mau ditampilkan di dashboard)
      await prefs.setString('nama', nama);
      await prefs.setString('email', email);

      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      print('Response: ${response.body}');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Login Failed'),
          content: Text('Email atau password salah'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Setoran Hafalan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 8),
            Text('Aplikasi Setoran Hafalan UIN Suska Riau', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 32),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.email),
                hintText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock),
                hintText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text('Forgot Your Password?'),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : login,
              child: isLoading ? CircularProgressIndicator() : Text('Log In'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}