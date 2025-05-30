import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(242, 252, 255, 1),
        ),
        child: Stack(
          children: [
            // Background gradient dengan curved bottom
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 358,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(201),
                    bottomRight: Radius.circular(201),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.25),
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    )
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color.fromRGBO(17, 93, 93, 1),
                      Color.fromRGBO(9, 121, 102, 1),
                      Color.fromRGBO(237, 250, 220, 1),
                    ],
                  ),
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 44,
              left: 25,
              child: SafeArea(
                child: IconButton(
                  icon: Image.asset(
                    'assets/images/back.png',
                    width: 24,
                    height: 24,
                    color: Colors.yellowAccent,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Profile Image
            Positioned(
              top: 86,
              left: (MediaQuery
                  .of(context)
                  .size
                  .width - 186) / 2,
              child: Container(
                width: 186,
                height: 186,
                decoration: BoxDecoration(
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.25),
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    )
                  ],
                  image: const DecorationImage(
                    image: AssetImage('assets/images/Ellipse2.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(93),
                ),
              ),
            ),

            // Profile Title
            Positioned(
              top: 290,
              left: 0,
              right: 0,
              child: Text(
                'Profil Mahasiswa',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),

            // Student Name
            Positioned(
              top: 380,
              left: 23,
              right: 23,
              child: Text(
                user.nama,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1),
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),

            // NIM
            Positioned(
              top: 450,
              left: 23,
              right: 23,
              child: Text(
                'NIM: ${user.nim}',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1),
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  height: 1.4,
                ),
              ),
            ),

            // Email
            Positioned(
              top: 420,
              left: 23,
              right: 23,
              child: Text(
                'Email: ${user.email}',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1),
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  height: 1.4,
                ),
              ),
            ),

            // Semester
            Positioned(
              top: 480,
              left: 23,
              right: 23,
              child: Text(
                'Semester: ${user.semester}',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1),
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  height: 1.4,
                ),
              ),
            ),

            // Angkatan
            Positioned(
              top: 510,
              left: 23,
              right: 23,
              child: Text(
                'Angkatan: ${user.angkatan}',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1),
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  height: 1.4,
                ),
              ),
            ),

            // Dosen PA
            Positioned(
              top: 540,
              left: 23,
              right: 23,
              child: Text(
                'Dosen PA: ${user.dosenPa.nama}',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1),
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
