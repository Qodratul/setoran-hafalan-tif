import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/setoran_model.dart';
import '../models/surah_model.dart';
import '../services/auth_service.dart';
import '../services/setoran_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  SetoranModel? setoranData;
  String searchQuery = '';
  List<SurahModel> filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
      _filterSurahs();
    });
    _loadSetoranData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSetoranData() async {
    setState(() => isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final setoranService = SetoranService(authService);

      final data = await setoranService.getSetoranSaya();

      if (data != null) {
        setState(() {
          setoranData = data;
          _filterSurahs();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data setoran')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterSurahs() {
    if (setoranData == null) return;

    List<SurahModel> allSurahs = setoranData!.setoran.detail;

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      allSurahs = allSurahs.where((surah) =>
      surah.nama.toLowerCase().contains(query) ||
          surah.label.toLowerCase().contains(query)
      ).toList();
    }

    setState(() {
      switch (_tabController.index) {
        case 0: // All Surahs
          filteredSurahs = allSurahs;
          break;
        case 1: // Belum Disetor
          filteredSurahs = allSurahs.where((surah) => !surah.sudahSetor).toList();
          break;
        case 2: // Sudah Disetor
          filteredSurahs = allSurahs.where((surah) => surah.sudahSetor).toList();
          break;
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
    _filterSurahs();
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = setoranData?.info;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Constants.primaryColor,
              Colors.teal,
              Color(0xFF00A890),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Constants.primaryColor,
                          ),
                        ),

                        const SizedBox(width: 50),

                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implementasi cetak kartu
                          },
                          icon: const Icon(Icons.print),
                          label: const Text('Cetak Kartu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Constants.primaryColor,
                          ),
                        ),
                        // Logout button
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Constants.primaryColor,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Assalamu\'alaikum',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      userInfo?.nama ?? 'Mahasiswa',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'NIM: ${userInfo?.nim ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Semester: ${userInfo?.semester ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Dosen Pembimbing: ${userInfo?.dosenPa.nama ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Search bar dan Tabs
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Cari surah',
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ),

                      TabBar(
                        controller: _tabController,
                        indicatorColor: Constants.primaryColor,
                        labelColor: Constants.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: 'Surah'),
                          Tab(text: 'Belum Disetor'),
                          Tab(text: 'Sudah Disetor'),
                        ],
                      ),

                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filteredSurahs.isEmpty
                            ? const Center(child: Text('Tidak ada data'))
                            : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredSurahs.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final surah = filteredSurahs[index];
                            return _buildSurahItem(surah);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahItem(SurahModel surah) {
    final String stageLabel = _getStageLabel(surah.label);

    return InkWell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Constants.primaryColor,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stageLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: null, // Disabled button to show status
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(stageLabel),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  String _getStageLabel(String code) {
    return Constants.labelMap[code] ?? code;
  }
}