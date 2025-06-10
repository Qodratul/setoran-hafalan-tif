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
  List<Setoran> _selectedSetoranToSave = [];
  List<Setoran> _selectedSetoranToCancel = [];
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
        _selectedSetoranToSave.clear();
        _selectedSetoranToCancel.clear();
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

  bool _isSelected(Setoran setoran) {
    if (setoran.sudahSetor) {
      return _selectedSetoranToCancel.contains(setoran);
    } else {
      return _selectedSetoranToSave.contains(setoran);
    }
  }

  void _toggleSelection(Setoran setoran) {
    setState(() {
      if (setoran.sudahSetor) {
        if (_selectedSetoranToCancel.contains(setoran)) {
          _selectedSetoranToCancel.remove(setoran);
        } else {
          _selectedSetoranToCancel.add(setoran);
        }
      } else {
        if (_selectedSetoranToSave.contains(setoran)) {
          _selectedSetoranToSave.remove(setoran);
        } else {
          _selectedSetoranToSave.add(setoran);
        }
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedFilter == 'Sudah Setor') {
        final sudahSetorList = _filteredSetoranList;
        final allSelected = sudahSetorList.every((s) => _selectedSetoranToCancel.contains(s));

        if (allSelected) {
          _selectedSetoranToCancel.removeWhere((s) => sudahSetorList.contains(s));
        } else {
          for (var setoran in sudahSetorList) {
            if (!_selectedSetoranToCancel.contains(setoran)) {
              _selectedSetoranToCancel.add(setoran);
            }
          }
        }
      } else if (_selectedFilter == 'Belum Setor') {
        final belumSetorList = _filteredSetoranList;
        final allSelected = belumSetorList.every((s) => _selectedSetoranToSave.contains(s));

        if (allSelected) {
          // Unselect all
          _selectedSetoranToSave.removeWhere((s) => belumSetorList.contains(s));
        } else {
          // Select all
          for (var setoran in belumSetorList) {
            if (!_selectedSetoranToSave.contains(setoran)) {
              _selectedSetoranToSave.add(setoran);
            }
          }
        }
      }
    });
  }

  bool get _isAllSelected {
    if (_selectedFilter == 'Sudah Setor') {
      return _filteredSetoranList.isNotEmpty &&
          _filteredSetoranList.every((s) => _selectedSetoranToCancel.contains(s));
    } else if (_selectedFilter == 'Belum Setor') {
      return _filteredSetoranList.isNotEmpty &&
          _filteredSetoranList.every((s) => _selectedSetoranToSave.contains(s));
    }
    return false;
  }

  Future<void> _simpanSetoran() async {
    if (_selectedSetoranToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih setoran yang ingin disimpan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final dataSetoran = _selectedSetoranToSave.map((s) => {
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
      _selectedSetoranToSave.clear();
      _selectedSetoranToCancel.clear();
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

  Future<void> _batalkanSetoran() async {
    if (_selectedSetoranToCancel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih setoran yang ingin dibatalkan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final dataSetoran = _selectedSetoranToCancel.map((s) => {
      'id': s.infoSetoran!.id,
      'id_komponen_setoran': s.id,
      'nama_komponen_setoran': s.nama,
    }).toList();

    debugPrint('🔄 Cancelling setoran: $dataSetoran');

    final success = await _dosenService.deleteSetoran(widget.nim, dataSetoran);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setoran berhasil dibatalkan'),
          backgroundColor: Colors.orange,
        ),
      );
      _selectedSetoranToSave.clear();
      _selectedSetoranToCancel.clear();
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
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final info = _mahasiswaData?['info'];
    final setoranInfo = _mahasiswaData?['setoran']['info_dasar'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        title: Text("Detail Setoran"),
        foregroundColor: Colors.white,
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

          // Select All Checkbox
          if (_selectedFilter != 'Semua' && _filteredSetoranList.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _isAllSelected,
                    onChanged: (value) => _toggleSelectAll(),
                    activeColor: _selectedFilter == 'Sudah Setor' ? Colors.red : Colors.green,
                  ),
                  Text(
                    'Pilih Semua (${_filteredSetoranList.length} item)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

          // Selection Summary
          if (_selectedSetoranToSave.isNotEmpty || _selectedSetoranToCancel.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedSetoranToSave.isNotEmpty)
                    Text(
                      'Dipilih untuk disimpan: ${_selectedSetoranToSave.length} item',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  if (_selectedSetoranToCancel.isNotEmpty)
                    Text(
                      'Dipilih untuk dibatalkan: ${_selectedSetoranToCancel.length} item',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

          // Setoran List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredSetoranList.length,
                itemBuilder: (context, index) {
                  final setoran = _filteredSetoranList[index];
                  final isSelected = _isSelected(setoran);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(
                        color: setoran.sudahSetor ? Colors.red : Colors.green,
                        width: 2,
                      )
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () => _toggleSelection(setoran),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
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
                                  if (setoran.sudahSetor && setoran.infoSetoran != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Disahkan: ${setoran.infoSetoran!.dosenYangMengesahkan.nama}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Tanggal: ${setoran.infoSetoran!.tglSetoran}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: setoran.sudahSetor
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    setoran.sudahSetor ? 'Sudah Setor' : 'Belum Setor',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: setoran.sudahSetor ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) => _toggleSelection(setoran),
                                  activeColor: setoran.sudahSetor ? Colors.red : Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedSetoranToSave.isEmpty ? null : _simpanSetoran,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      'Simpan (${_selectedSetoranToSave.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedSetoranToSave.isEmpty
                          ? Colors.grey
                          : Constants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedSetoranToCancel.isEmpty ? null : _batalkanSetoran,
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: Text(
                      'Batalkan (${_selectedSetoranToCancel.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedSetoranToCancel.isEmpty
                          ? Colors.grey
                          : Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}