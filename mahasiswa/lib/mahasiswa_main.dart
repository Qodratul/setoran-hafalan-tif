import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  await dotenv.load(fileName: ".env");
  debugPrint(dotenv.get('baseUrl', fallback: 'null'));
  debugPrint (dotenv.get('empowerBaseUrl', fallback: 'null'));
  runApp(MyApp(token: token));
}

class MyApp extends StatelessWidget {
  final String? token;

  const MyApp({Key? key, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Setoran Hafalan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF006666),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: const Color(0xFF006666),
            secondary: const Color(0xFFD4AF37),
          ),
          fontFamily: 'Poppins',
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
        home: token != null ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }
}