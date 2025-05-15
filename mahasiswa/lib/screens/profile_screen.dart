import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '/constants.dart';
class ProfileScreen extends StatelessWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Constants.primaryColor,
              Colors.teal,
              Color(0xFF00A890),
              // Color(0xFF115d5d),
              // Color(0xFF097C66),
              Color(0xFFC0EFB9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Profil Mahasiswa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                  top: 86,
                  left: 108,
                  child: Container(
                      width: 186,
                      height: 186,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.25),
                              offset: Offset(0, 4),
                              blurRadius: 4
                          )
                        ],
                        image: DecorationImage(
                            image: AssetImage('assets/images/Ellipse2.png'),
                            fit: BoxFit.fitWidth
                        ),
                        borderRadius: BorderRadius.all(Radius.elliptical(186, 186)),
                      )
                  )
              ),

              // Isi Profil
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Mahasiswa
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            user.nama,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'NIM: ${user.nim}',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          Text(
                            'Email: ${user.email}',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          Text(
                            'Angkatan: ${user.angkatan}',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          Text(
                            'Semester: ${user.semester}',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          Text(
                            'Dosen PA: ${user.dosenPa.nama}',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
