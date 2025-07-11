class UserModel {
  final String nama;
  final String nim;
  final String email;
  final String angkatan;
  final int semester;
  final DosenModel dosenPa;

  UserModel({
    required this.nama,
    required this.nim,
    required this.email,
    required this.angkatan,
    required this.semester,
    required this.dosenPa,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nama: json['nama'] ?? '',
      nim: json['nim'] ?? '',
      email: json['email'] ?? '',
      angkatan: json['angkatan'] ?? '',
      semester: json['semester'] ?? 0,
      dosenPa: DosenModel.fromJson(json['dosen_pa'] ?? {}),
    );
  }
}

class DosenModel {
  final String nip;
  final String nama;
  final String email;

  DosenModel({
    required this.nip,
    required this.nama,
    required this.email,
  });

  factory DosenModel.fromJson(Map<String, dynamic> json) {
    return DosenModel(
      nip: json['nip'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
    );
  }
}