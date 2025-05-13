import 'package:mahasiswa/models/user_model.dart';

class SurahModel {
  final String id;
  final String nama;
  final String label;
  final bool sudahSetor;
  final InfoSetoran? infoSetoran;

  SurahModel({
    required this.id,
    required this.nama,
    required this.label,
    required this.sudahSetor,
    this.infoSetoran,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      label: json['label'] ?? '',
      sudahSetor: json['sudah_setor'] ?? false,
      infoSetoran: json['info_setoran'] != null
          ? InfoSetoran.fromJson(json['info_setoran'])
          : null,
    );
  }
}

class InfoSetoran {
  final String id;
  final String tglSetoran;
  final String tglValidasi;
  final DosenModel dosenYangMengesahkan;

  InfoSetoran({
    required this.id,
    required this.tglSetoran,
    required this.tglValidasi,
    required this.dosenYangMengesahkan,
  });

  factory InfoSetoran.fromJson(Map<String, dynamic> json) {
    return InfoSetoran(
      id: json['id'] ?? '',
      tglSetoran: json['tgl_setoran'] ?? '',
      tglValidasi: json['tgl_validasi'] ?? '',
      dosenYangMengesahkan: DosenModel.fromJson(json['dosen_yang_mengesahkan'] ?? {}),
    );
  }
}