import 'package:mahasiswa/models/surah_model.dart';
import 'package:mahasiswa/models/user_model.dart';

class SetoranModel {
  final UserModel info;
  final SetoranData setoran;

  SetoranModel({
    required this.info,
    required this.setoran,
  });

  factory SetoranModel.fromJson(Map<String, dynamic> json) {
    return SetoranModel(
      info: UserModel.fromJson(json['info'] ?? {}),
      setoran: SetoranData.fromJson(json['setoran'] ?? {}),
    );
  }
}

class SetoranData {
  final List<LogEntry> log;
  final InfoDasar infoDasar;
  final List<RingkasanSetoran> ringkasan;
  final List<SurahModel> detail;

  SetoranData({
    required this.log,
    required this.infoDasar,
    required this.ringkasan,
    required this.detail,
  });

  factory SetoranData.fromJson(Map<String, dynamic> json) {
    return SetoranData(
      log: (json['log'] as List? ?? []).map((log) => LogEntry.fromJson(log)).toList(),
      infoDasar: InfoDasar.fromJson(json['info_dasar'] ?? {}),
      ringkasan: (json['ringkasan'] as List? ?? []).map((item) => RingkasanSetoran.fromJson(item)).toList(),
      detail: (json['detail'] as List? ?? []).map((item) => SurahModel.fromJson(item)).toList(),
    );
  }
}

class LogEntry {
  final int id;
  final String keterangan;
  final String aksi;
  final String timestamp;
  final DosenModel? dosenYangMengesahkan;

  LogEntry({
    required this.id,
    required this.keterangan,
    required this.aksi,
    required this.timestamp,
    this.dosenYangMengesahkan,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] ?? 0,
      keterangan: json['keterangan'] ?? '',
      aksi: json['aksi'] ?? '',
      timestamp: json['timestamp'] ?? '',
      dosenYangMengesahkan: json['dosen_yang_mengesahkan'] != null
          ? DosenModel.fromJson(json['dosen_yang_mengesahkan'])
          : null,
    );
  }
}

class InfoDasar {
  final int totalWajibSetor;
  final int totalSudahSetor;
  final int totalBelumSetor;
  final double persentaseProgresSetor;
  final String tglTerakhirSetor;
  final String terakhirSetor;

  InfoDasar({
    required this.totalWajibSetor,
    required this.totalSudahSetor,
    required this.totalBelumSetor,
    required this.persentaseProgresSetor,
    required this.tglTerakhirSetor,
    required this.terakhirSetor,
  });

  factory InfoDasar.fromJson(Map<String, dynamic> json) {
    return InfoDasar(
      totalWajibSetor: json['total_wajib_setor'] ?? 0,
      totalSudahSetor: json['total_sudah_setor'] ?? 0,
      totalBelumSetor: json['total_belum_setor'] ?? 0,
      persentaseProgresSetor: double.tryParse(json['persentase_progres_setor'].toString()) ?? 0.0,
      tglTerakhirSetor: json['tgl_terakhir_setor'] ?? '',
      terakhirSetor: json['terakhir_setor'] ?? '',
    );
  }
}

class RingkasanSetoran {
  final String label;
  final int totalWajibSetor;
  final int totalSudahSetor;
  final int totalBelumSetor;
  final double persentaseProgresSetor;

  RingkasanSetoran({
    required this.label,
    required this.totalWajibSetor,
    required this.totalSudahSetor,
    required this.totalBelumSetor,
    required this.persentaseProgresSetor,
  });

  factory RingkasanSetoran.fromJson(Map<String, dynamic> json) {
    return RingkasanSetoran(
      label: json['label'] ?? '',
      totalWajibSetor: json['total_wajib_setor'] ?? 0,
      totalSudahSetor: json['total_sudah_setor'] ?? 0,
      totalBelumSetor: json['total_belum_setor'] ?? 0,
      persentaseProgresSetor: double.tryParse(json['persentase_progres_setor'].toString()) ?? 0.0,
    );
  }
}
