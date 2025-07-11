class Dosen {
  final String nip;
  final String nama;
  final String email;

  Dosen({
    required this.nip,
    required this.nama,
    required this.email,
  });

  factory Dosen.fromJson(Map<String, dynamic> json) {
    return Dosen(
      nip: json['nip'],
      nama: json['nama'],
      email: json['email'],
    );
  }
}