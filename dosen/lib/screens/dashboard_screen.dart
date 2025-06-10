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

class _DashboardScreenState extends State<DashboardScreen> {
  final DosenService _dosenService = DosenService();
  Map<String, dynamic>? _dosenData;
  List<Mahasiswa> _mahasiswaList = [];
  List<Mahasiswa> _filteredMahasiswaList = [];
  bool _isLoading = true;
  String _selectedAngkatan = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  bool _isDisposed = false;
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _initializeScreen();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();

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
    if (_isDisposed || !mounted) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (!authService.isAuthenticated) {
        if (mounted && !_isDisposed) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Sesi tidak valid. Silakan login ulang.');
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final hasValidToken = await _ensureValidTokenSafely(authService);

      if (!hasValidToken) {
        if (mounted && !_isDisposed) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Sesi tidak valid. Silakan login ulang.');
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
            _filteredMahasiswaList = _mahasiswaList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted && !_isDisposed) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Gagal memuat data. Silakan coba lagi.');
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Terjadi kesalahan saat memuat data.');
      }
    }
  }

  Future<bool> _ensureValidTokenSafely(AuthService authService) async {
    try {
      return await authService.ensureValidToken(showDialog: false);
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
    final angkatanSet = _mahasiswaList.map((m) => m.angkatan).toSet();
    return ['Semua', ...angkatanSet];
  }

  Future<void> _checkTokenStatus(AuthService authService) async {
    try {
      await _ensureValidTokenSafely(authService);
    } catch (e) {
      debugPrint('Error checking token status: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (_isDisposed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
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

            _buildSessionStatusIndicator(),

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

            // Statistics Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Mahasiswa',
                      _mahasiswaList.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Sudah Setor',
                      _mahasiswaList.where((m) => m.infoSetoran.totalSudahSetor > 0).length.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Belum Setor',
                      _mahasiswaList.where((m) => m.infoSetoran.totalSudahSetor == 0).length.toString(),
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Mahasiswa List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                          'Progress Setoran',
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

  Widget _buildSessionStatusIndicator() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.willExpireSoon) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sesi akan berakhir dalam 5 menit',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (!_isDisposed && mounted) {
                      try {
                        await authService.handleTokenRefresh(showDialog: true);
                      } catch (e) {
                        debugPrint('Error refreshing token: $e');
                      }
                    }
                  },
                  child: const Text(
                    'Perpanjang',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
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