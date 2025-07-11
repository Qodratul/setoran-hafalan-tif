class Mahasiswa {
  final String nim;
  final String nama;
  final String email;
  final String angkatan;
  final int semester;
  final InfoSetoran infoSetoran;

  Mahasiswa({
    required this.nim,
    required this.nama,
    required this.email,
    required this.angkatan,
    required this.semester,
    required this.infoSetoran,
  });

  factory Mahasiswa.fromJson(Map<String, dynamic> json) {
    return Mahasiswa(
      nim: json['nim'],
      nama: json['nama'],
      email: json['email'],
      angkatan: json['angkatan'],
      semester: json['semester'],
      infoSetoran: InfoSetoran.fromJson(json['info_setoran']),
    );
  }
}

class InfoSetoran {
  final int totalWajibSetor;
  final int totalSudahSetor;
  final int totalBelumSetor;
  final double persentaseProgresSetor;
  final String? tglTerakhirSetor;
  final String terakhirSetor;

  InfoSetoran({
    required this.totalWajibSetor,
    required this.totalSudahSetor,
    required this.totalBelumSetor,
    required this.persentaseProgresSetor,
    this.tglTerakhirSetor,
    required this.terakhirSetor,
  });

  factory InfoSetoran.fromJson(Map<String, dynamic> json) {
    return InfoSetoran(
      totalWajibSetor: json['total_wajib_setor'],
      totalSudahSetor: json['total_sudah_setor'],
      totalBelumSetor: json['total_belum_setor'],
      persentaseProgresSetor: json['persentase_progres_setor'].toDouble(),
      tglTerakhirSetor: json['tgl_terakhir_setor'],
      terakhirSetor: json['terakhir_setor'],
    );
  }
}