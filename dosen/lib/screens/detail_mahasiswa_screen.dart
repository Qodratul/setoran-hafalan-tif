import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import '../services/dosen_service.dart';
import '../models/setoran_model.dart';
import '../constants.dart';

class DetailMahasiswaScreen extends StatefulWidget {
  final String nim;

  const DetailMahasiswaScreen({Key? key, required this.nim}) : super(key: key);

  @override
  _DetailMahasiswaScreenState createState() => _DetailMahasiswaScreenState();
}

class _DetailMahasiswaScreenState extends State<DetailMahasiswaScreen> with TickerProviderStateMixin {
  final DosenService _dosenService = DosenService();
  Map<String, dynamic>? _mahasiswaData;
  List<Setoran> _setoranList = [];
  List<Setoran> _cartToSave = [];
  List<Setoran> _cartToCancel = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _selectAllBelumSetor = false;
  bool _selectAllSudahSetor = false;

  TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dateController.dispose();
    super.dispose();
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
        _cartToSave.clear();
        _cartToCancel.clear();
        _selectAllBelumSetor = false;
        _selectAllSudahSetor = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Setoran> get _filteredSetoranList {
    if (_selectedFilter == 'Semua') {
      return _setoranList;
    } else if (_selectedFilter == "Sudah di-muroja'ah") {
      return _setoranList.where((s) => s.sudahSetor).toList();
    } else if (_selectedFilter == "Belum di-muroja'ah") {
      return _setoranList.where((s) => !s.sudahSetor).toList();
    } else {
      return _setoranList.where((s) => s.label == _selectedFilter).toList();
    }
  }

  void _toggleCart(Setoran setoran) {
    setState(() {
      if (setoran.sudahSetor) {
        _cartToSave.clear();
        if (_cartToCancel.contains(setoran)) {
          _cartToCancel.remove(setoran);
        } else {
          _cartToCancel.add(setoran);
        }
      } else {
        _cartToCancel.clear();
        if (_cartToSave.contains(setoran)) {
          _cartToSave.remove(setoran);
        } else {
          _cartToSave.add(setoran);
        }
      }
    });
  }

  bool _isInCart(Setoran setoran) {
    return _cartToSave.contains(setoran) || _cartToCancel.contains(setoran);
  }

  Future<void> _simpanSetoran() async {
    if (_cartToSave.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pilih tanggal setoran terlebih dahulu."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dataSetoran = _cartToSave.map((s) => {
      'nama_komponen_setoran': s.nama,
      'id_komponen_setoran': s.id,
    }).toList();

    final success = await _dosenService.simpanSetoran(
      widget.nim,
      dataSetoran,
      _selectedDate!.toIso8601String().split('T')[0],
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Muroja'ah berhasil disimpan"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menyimpan muroja'ah"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _batalkanSetoran() async {
    if (_cartToCancel.isEmpty) return;

    final dataSetoran = _cartToCancel.map((s) => {
      'id': s.infoSetoran!.id,
      'id_komponen_setoran': s.id,
      'nama_komponen_setoran': s.nama,
    }).toList();

    final success = await _dosenService.deleteSetoran(widget.nim, dataSetoran);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Muroja'ah berhasil dibatalkan"),
          backgroundColor: Colors.orange,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal membatalkan Muroja'ah"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButtons() {
    if (_cartToSave.isNotEmpty && _cartToCancel.isEmpty) {
      return ElevatedButton.icon(
        onPressed: () => _showSaveSetoranModal(context),
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(
          'Simpan (${_cartToSave.length})',
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else if (_cartToCancel.isNotEmpty && _cartToSave.isEmpty) {
      return ElevatedButton.icon(
        onPressed: _batalkanSetoran,
        icon: const Icon(Icons.cancel, color: Colors.white),
        label: Text(
          'Batal (${_cartToCancel.length})',
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Future<void> _generateAndOpenStudentPdf() async {
    _showLoadingDialog();

    final filePath = await _dosenService.getKartuMurojaahMahasiswaPdf(widget.nim);

    Navigator.pop(context);

    if (filePath != null) {
      OpenFilex.open(filePath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat kartu murojaah PDF untuk mahasiswa ini.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Membuat PDF..."),
            ],
          ),
        );
      },
    );
  }

  void _toggleSelectAll(bool isSudahSetor, bool? value) {
    setState(() {
      if (isSudahSetor) {
        _selectAllSudahSetor = value ?? false;
        _cartToSave.clear();
        if (_selectAllSudahSetor) {
          _cartToCancel.addAll(_setoranList.where((s) => s.sudahSetor && !_cartToCancel.contains(s)));
        } else {
          _cartToCancel.clear();
        }
      } else {
        _selectAllBelumSetor = value ?? false;
        _cartToCancel.clear();
        if (_selectAllBelumSetor) {
          _cartToSave.addAll(_setoranList.where((s) => !s.sudahSetor && !_cartToSave.contains(s)));
        } else {
          _cartToSave.clear();
        }
      }
    });
  }

  void _showSaveSetoranModal(BuildContext context) {
    _selectedDate = DateTime.now();
    _dateController.text = "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Simpan Setoran Hafalan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Constants.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                style: const TextStyle(
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Tanggal Setoran',
                  hintText: 'DD/MM/YYYY',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today,
                      color: Constants.primaryColor),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 12,
                  ),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: Constants.primaryColor,
                          colorScheme: const ColorScheme.light(
                            primary: Constants.primaryColor,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                          buttonTheme: const ButtonThemeData(
                            textTheme: ButtonTextTheme.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                      _dateController.text =
                      "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Constants.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Constants.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _simpanSetoran,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Constants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
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

    if (_cartToSave.isNotEmpty || _cartToCancel.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationController.forward();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationController.reverse();
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        title: const Text("Detail Muroja'ah Juz 30"),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _generateAndOpenStudentPdf,
          ),
        ],
      ),
      body: Column(
        children: [
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
                            "Progress Muroja'ah",
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

          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                "Semua",
                "Sudah di-muroja'ah",
                "Belum di-muroja'ah",
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
                        _selectAllBelumSetor = false;
                        _selectAllSudahSetor = false;
                        _cartToSave.clear();
                        _cartToCancel.clear();
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Constants.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (_selectedFilter == "Sudah di-muroja'ah" || _selectedFilter == "Belum di-muroja'ah")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedFilter == "Sudah di-muroja'ah" ? _selectAllSudahSetor : _selectAllBelumSetor,
                    onChanged: (value) {
                      _toggleSelectAll(_selectedFilter == "Sudah di-muroja'ah", value);
                    },
                    activeColor: Constants.primaryColor,
                  ),
                  Text(
                    'Pilih Semua ${_selectedFilter == "Sudah di-muroja'ah" ? "Sudah di-muroja'ah" : "Belum di-muroja'ah"}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredSetoranList.length,
                itemBuilder: (context, index) {
                  final setoran = _filteredSetoranList[index];
                  final isInCart = _isInCart(setoran);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isInCart
                          ? BorderSide(
                        color: setoran.sudahSetor ? Colors.red : Colors.green,
                        width: 2,
                      )
                          : BorderSide.none,
                    ),
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
                                      color: Colors.green,
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
                                  setoran.sudahSetor ? "Sudah di-muroja'ah" : "Belum di-muroja'ah",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: setoran.sudahSetor ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.w600                               ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _toggleCart(setoran),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInCart
                                      ? (setoran.sudahSetor ? Colors.red : Colors.grey)
                                      : (setoran.sudahSetor ? Colors.orange : Constants.primaryColor),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  isInCart
                                      ? (setoran.sudahSetor ? 'Hapus' : 'Batal')
                                      : (setoran.sudahSetor ? 'Batal' : 'Simpan'),
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SlideTransition(
            position: _slideAnimation,
            child: Container(
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
              child: _buildActionButtons(),
            ),
          ),
        ],
      ),
    );
  }
}