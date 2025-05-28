import 'package:flutter/material.dart';
import '../services/dosen_service.dart';
import '../models/setoran_model.dart';
import '../constants.dart';

class DetailMahasiswaScreen extends StatefulWidget {
  final String nim;

  const DetailMahasiswaScreen({Key? key, required this.nim}) : super(key: key);

  @override
  _DetailMahasiswaScreenState createState() => _DetailMahasiswaScreenState();
}

class _DetailMahasiswaScreenState extends State<DetailMahasiswaScreen> {
  final DosenService _dosenService = DosenService();
  Map<String, dynamic>? _mahasiswaData;
  List<Setoran> _setoranList = [];
  List<Setoran> _selectedSetoran = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final data = await _dosenService.getSetoranMahasiswa(widget.nim);
    if (data != null && data['response'] == true) {
    setState(() {
      _mahasiswaData = data['data'];
      _setoranList = (data['data']['setoran']['detail'] as List)
          .map((e) => Setoran.fromJson(e))
          .toList();
      _isLoading = false;
    });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Setoran> get _filteredSetoranList {
    if (_selectedFilter == 'Semua') {
      return _setoranList;
    } else if (_selectedFilter == 'Sudah Setor') {
      return _setoranList.where((s) => s.sudahSetor).toList();
    } else if (_selectedFilter == 'Belum Setor') {
      return _setoranList.where((s) => !s.sudahSetor).toList();
    } else {
      return _setoranList.where((s) => s.label == _selectedFilter).toList();
    }
  }

  Future<void> _simpanSetoran() async {
    if (_selectedSetoran.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih setoran terlebih dahulu')),
      );
      return;
    }

    final dataSetoran = _selectedSetoran.map((s) => {
      'nama_komponen_setoran': s.nama,
      'id_komponen_setoran': s.id,
    }).toList();

    final success = await _dosenService.simpanSetoran(
      widget.nim,
      dataSetoran,
      DateTime.now().toIso8601String().split('T')[0],
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
        content: Text('Setoran berhasil disimpan'),
        backgroundColor: Colors.green,
      ),
    );
    _selectedSetoran.clear();
    _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
        content: Text('Gagal menyimpan setoran'),
        backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _batalkanSetoran(List<Setoran> setoranList) async {
    final dataSetoran = setoranList.map((s) => {
      'id': s.infoSetoran!.id,
      'id_komponen_setoran': s.id,
      'nama_komponen_setoran': s.nama,
    }).toList();

    final success = await _dosenService.deleteSetoran(widget.nim, dataSetoran);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
        content: Text('Setoran berhasil dibatalkan'),
        backgroundColor: Colors.orange,
        ),
      );
    _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
        content: Text('Gagal membatalkan setoran'),
        backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Constants.primaryColor,
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final info = _mahasiswaData?['info'];
    final setoranInfo = _mahasiswaData?['setoran']['info_dasar'];
    final ringkasan = _mahasiswaData?['setoran']['ringkasan'] as List?;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        title: Text(info?['nama'] ?? ''),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            decoration: BoxDecoration(
              color: Constants.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        info?['nama']?.substring(0, 1).toUpperCase() ?? '',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info?['nama'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${info?['nim']} • Semester ${info?['semester']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            info?['email'] ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress Setoran',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${setoranInfo?['persentase_progres_setor']?.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (setoranInfo?['persentase_progres_setor'] ?? 0) / 100,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${setoranInfo?['total_sudah_setor']} dari ${setoranInfo?['total_wajib_setor']} surat',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Terakhir: ${setoranInfo?['terakhir_setor']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                'Semua',
                'Sudah Setor',
                'Belum Setor',
              ].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Constants.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Setoran List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSetoranList.length,
              itemBuilder: (context, index) {
                final setoran = _filteredSetoranList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (setoran.sudahSetor) {
                        _selectedSetoran.remove(setoran);
                        } else {
                        _selectedSetoran.add(setoran);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                setoran.nama,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                setoran.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Checkbox(
                            value: _selectedSetoran.contains(setoran),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                _selectedSetoran.add(setoran);
                                } else {
                                _selectedSetoran.remove(setoran);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _simpanSetoran,
                style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Simpan Setoran'),
              ),
                ElevatedButton(
                  onPressed: () {
                  _batalkanSetoran(_selectedSetoran);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Batalkan Setoran'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}