import 'dosen_model.dart';

class Setoran {
  final String id;
  final String nama;
  final String label;
  final bool sudahSetor;
  final InfoSetoranDetail? infoSetoran;

  Setoran({
    required this.id,
    required this.nama,
    required this.label,
    required this.sudahSetor,
    this.infoSetoran,
  });

  factory Setoran.fromJson(Map<String, dynamic> json) {
    return Setoran(
      id: json['id'],
      nama: json['nama'],
      label: json['label'],
      sudahSetor: json['sudah_setor'],
      infoSetoran: json['info_setoran'] != null
          ? InfoSetoranDetail.fromJson(json['info_setoran'])
          : null,
    );
  }
}

class InfoSetoranDetail {
  final String id;
  final String tglSetoran;
  final String tglValidasi;
  final Dosen dosenYangMengesahkan;

  InfoSetoranDetail({
    required this.id,
    required this.tglSetoran,
    required this.tglValidasi,
    required this.dosenYangMengesahkan,
  });

  factory InfoSetoranDetail.fromJson(Map<String, dynamic> json) {
    return InfoSetoranDetail(
      id: json['id'],
      tglSetoran: json['tgl_setoran'],
      tglValidasi: json['tgl_validasi'],
      dosenYangMengesahkan: Dosen.fromJson(json['dosen_yang_mengesahkan']),
    );
  }
}