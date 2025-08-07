import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/dosen_service.dart';
import '../models/mahasiswa_model.dart';
import '../constants.dart';
import 'login_screen.dart';
import 'detail_mahasiswa_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late DosenService _dosenService;
  Map<String, dynamic>? _dosenData;
  List<Mahasiswa> _mahasiswaList = [];
  List<Mahasiswa> _filteredMahasiswaList = [];
  bool _isLoading = true;
  String _selectedAngkatan = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  bool _isDisposed = false;
  AuthService? _authService;

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _initializeScreen();
      }
    });
  }

  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    _pulseAnimationController.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = Provider.of<AuthService>(context, listen: false);
    _dosenService = DosenService(_authService!);
    _dosenService.setContext(context);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    _pulseAnimationController.dispose(); // Dispose animation controller

    if (_authService != null) {
      _authService!.clearContext();
    }

    super.dispose();
  }

  Future<void> _initializeScreen() async {
    if (_isDisposed) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.setContext(context);
      await _checkTokenStatus(authService);
      await _loadData();
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final hasValidToken = await authService.ensureValidToken();

      if (!hasValidToken) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final data = await _dosenService.getPASaya();
      if (data != null && data['response'] == true) {
        if (mounted && !_isDisposed) {
          setState(() {
            _dosenData = data['data'];
            _mahasiswaList = (data['data']['info_mahasiswa_pa']['daftar_mahasiswa'] as List)
                .map((e) => Mahasiswa.fromJson(e))
                .toList();
            _filterMahasiswa();
            _isLoading = false;
          });
        }
      } else {
        if (mounted && !_isDisposed) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _ensureValidTokenSafely(AuthService authService) async {
    try {
      return await authService.ensureValidToken();
    } catch (e) {
      debugPrint('Error ensuring valid token: $e');
      return false;
    }
  }

  void _filterMahasiswa() {
    if (_isDisposed || !mounted) return;

    setState(() {
      _filteredMahasiswaList = _mahasiswaList.where((mahasiswa) {
        final matchesSearch = mahasiswa.nama.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            mahasiswa.nim.contains(_searchController.text);
        final matchesAngkatan = _selectedAngkatan == 'Semua' || mahasiswa.angkatan == _selectedAngkatan;
        return matchesSearch && matchesAngkatan;
      }).toList();
    });
  }

  List<String> _getAngkatanList() {
    final angkatanSet = _mahasiswaList.map((m) => m.angkatan).toSet().toList();
    angkatanSet.sort();
    return ['Semua', ...angkatanSet];
  }

  Future<void> _checkTokenStatus(AuthService authService) async {
    try {
      await authService.ensureValidToken();
    } catch (e) {
      debugPrint('Error checking token status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Constants.primaryColor,
                    Constants.primaryColor.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard Dosen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dosenData?['nama'] ?? 'Loading...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            if (_dosenData != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Total Mahasiswa: ${_mahasiswaList.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 30
                          ),
                          onPressed: () async {
                            _showLogoutConfirmationDialog();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black),
                        onChanged: (_) => _filterMahasiswa(),
                        decoration: const InputDecoration(
                          hintText: 'Cari mahasiswa...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Angkatan
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _getAngkatanList().map((angkatan) {
                  final isSelected = _selectedAngkatan == angkatan;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(angkatan),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (!_isDisposed && mounted) {
                          setState(() {
                            _selectedAngkatan = angkatan;
                            _filterMahasiswa();
                          });
                        }
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

            // Mahasiswa List
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : RefreshIndicator(
                onRefresh: _loadData,
                child: _filteredMahasiswaList.isEmpty && !_isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredMahasiswaList.length,
                  itemBuilder: (context, index) {
                    final mahasiswa = _filteredMahasiswaList[index];
                    return _buildMahasiswaCard(mahasiswa);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: const Icon(
                        Icons.hourglass_empty,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Memuat data mahasiswa...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mohon tunggu sebentar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Tidak ada data mahasiswa',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tarik ke bawah untuk memperbarui',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMahasiswaCard(Mahasiswa mahasiswa) {
    final progress = mahasiswa.infoSetoran.persentaseProgresSetor;
    final progressColor = progress == 0 ? Colors.red
        : progress < 50 ? Colors.orange
        : progress < 100 ? Colors.blue
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailMahasiswaScreen(nim: mahasiswa.nim),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Constants.primaryColor.withOpacity(0.1),
                    child: Text(
                      mahasiswa.nama.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Constants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mahasiswa.nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${mahasiswa.nim} • Angkatan ${mahasiswa.angkatan}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Progress Muroja'ah",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mahasiswa.infoSetoran.totalSudahSetor}/${mahasiswa.infoSetoran.totalWajibSetor} (${progress.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: progressColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: mahasiswa.infoSetoran.terakhirSetor == 'Belum ada'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mahasiswa.infoSetoran.terakhirSetor,
                      style: TextStyle(
                        fontSize: 12,
                        color: mahasiswa.infoSetoran.terakhirSetor == 'Belum ada'
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    if (_isDisposed || !mounted) return;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    if (_authService != null) {
                      await _authService!.logout();
                    }
                    if (mounted && !_isDisposed) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error during logout: $e');
                  }
                },
                child: const Text('Keluar'),
              ),
            ],
          );
        });
  }
}