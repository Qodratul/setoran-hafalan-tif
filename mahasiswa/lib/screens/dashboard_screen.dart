import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/setoran_model.dart';
import '../models/surah_model.dart';
import '../services/auth_service.dart';
import '../services/setoran_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  bool _isLoading = true;
  bool _isRefreshing = false;
  SetoranModel? _setoranData;
  String _searchQuery = '';
  List<SurahModel> _filteredSurahs = [];

  // Text editing controller untuk search
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _initializeAnimations();
    _loadSetoranData();
  }

  void _initializeTabController() {
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _initializeAnimations() {
    // Animation untuk progress bar
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    // Animation untuk pulse effect
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

    // Start pulse animation
    _pulseAnimationController.repeat(reverse: true);
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
      _filterSurahs();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _progressAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSetoranData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final setoranService = SetoranService(authService);
      final data = await setoranService.getSetoranSaya();

      if (!mounted) return;

      if (data != null) {
        setState(() {
          _setoranData = data;
        });
        _filterSurahs();
        // Start progress animation setelah data dimuat
        _progressAnimationController.forward();
      } else {
        _showErrorSnackBar('Gagal memuat data setoran');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing || !mounted) return;

    setState(() => _isRefreshing = true);

    try {
      final authService = context.read<AuthService>();
      final setoranService = SetoranService(authService);
      final data = await setoranService.getSetoranSaya();

      if (!mounted) return;

      if (data != null) {
        setState(() {
          _setoranData = data;
        });
        _filterSurahs();
        // Reset dan restart animation untuk refresh
        _progressAnimationController.reset();
        _progressAnimationController.forward();
        _showSuccessSnackBar('Data berhasil diperbarui');
      } else {
        _showErrorSnackBar('Gagal memperbarui data setoran');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error saat memperbarui: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _filterSurahs() {
    if (_setoranData?.setoran.detail == null) return;

    List<SurahModel> allSurahs = _setoranData!.setoran.detail;

    // Filter berdasarkan search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      allSurahs = allSurahs.where((surah) =>
      surah.nama.toLowerCase().contains(query) ||
          surah.label.toLowerCase().contains(query)
      ).toList();
    }

    // Filter berdasarkan tab yang aktif
    List<SurahModel> filteredByTab;
    switch (_tabController.index) {
      case 0: // All Surahs
        filteredByTab = allSurahs;
        break;
      case 1: // Belum Disetor
        filteredByTab = allSurahs.where((surah) => !surah.sudahSetor).toList();
        break;
      case 2: // Sudah Disetor
        filteredByTab = allSurahs.where((surah) => surah.sudahSetor).toList();
        break;
      default:
        filteredByTab = allSurahs;
    }

    if (mounted) {
      setState(() {
        _filteredSurahs = filteredByTab;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterSurahs();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  Future<void> _logout() async {
    final confirmed = await _showLogoutConfirmation();
    if (confirmed == true) {
      try {
        final authService = context.read<AuthService>();
        await authService.logout();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Gagal logout: $e');
        }
      }
    }
  }

  Future<bool?> _showLogoutConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToProfile() {
    final userInfo = _setoranData?.info;
    if (userInfo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(user: userInfo),
        ),
      );
    }
  }

  void _showSurahDetails(SurahModel surah) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations
          .of(context)
          .modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 60,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Custom Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            //Color(0xFF00A890),
                            Color(0xFF115d5d),
                            Color(0xFF097C66),
                            //Color(0xFFC0EFB9),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Info Setoran',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  surah.nama,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Close button
                          // Container(
                          //   decoration: BoxDecoration(
                          //     color: Colors.white.withOpacity(0.2),
                          //     borderRadius: BorderRadius.circular(8),
                          //   ),
                          //   child: IconButton(
                          //     onPressed: () => Navigator.pop(context),
                          //     icon: const Icon(
                          //       Icons.close,
                          //       color: Colors.white,
                          //       size: 20,
                          //     ),
                          //     padding: const EdgeInsets.all(8),
                          //     constraints: const BoxConstraints(),
                          //   ),
                          // ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildSurahDetailsContent(surah),
                      ),
                    ),

                    // Bottom Action
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade600,
                                  Colors.grey.shade700
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, size: 18),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Tutup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildSurahDetailsContent(SurahModel surah) {
    if (surah.infoSetoran == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade600,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Belum ada info setoran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade800,
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

    final info = surah.infoSetoran!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.white,
            Colors.blue.shade50,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header dengan icon
          // Container(
          //   padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [Colors.green.shade400, Colors.green.shade600],
          //     ),
          //     borderRadius: BorderRadius.circular(12),
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.green.withOpacity(0.3),
          //         blurRadius: 8,
          //         offset: const Offset(0, 2),
          //       ),
          //     ],
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Icon(
          //         Icons.check_circle_outline,
          //         color: Colors.white,
          //         size: 24,
          //       ),
          //       const SizedBox(width: 8),
          //       Text(
          //         'Info Setoran Surah',
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 18,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 20),

          // Detail rows
          _buildDetailRow(
            'Tanggal Setoran',
            info.tglSetoran,
            Icons.calendar_today,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Tanggal Validasi',
            info.tglValidasi,
            Icons.verified,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Dosen Pengesah',
            info.dosenYangMengesahkan.nama,
            Icons.person_outline,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Decorative element
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildGradientDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Constants.primaryColor,
          Colors.teal,
          Color(0xFF00A890),
          Color(0xFF115d5d),
          Color(0xFF097C66),
          Color(0xFFC0EFB9),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderActions(),
          const SizedBox(height: 24),
          _buildUserInfo(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildProfileAvatar(),
        const Spacer(),
        _buildPrintButton(),
        const SizedBox(width: 12),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: _navigateToProfile,
      child: const CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.person,
          size: 40,
          color: Constants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildPrintButton() {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Implementasi cetak kartu
        _showErrorSnackBar('Fitur cetak kartu belum tersedia');
      },
      icon: const Icon(Icons.print),
      label: const Text('Cetak Kartu'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Constants.primaryColor,
        elevation: 2,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      onPressed: _logout,
      icon: Image.asset(
        'assets/images/out.png',
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.logout, color: Colors.white);
        },
      ),
    );
  }

  Widget _buildUserInfo() {
    final userInfo = _setoranData?.info;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              _buildProgressSection(),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildAvatarImage(),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Colors.white.withOpacity(0.9),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Progress Setoran',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        _setoranData != null
            ? _buildEnhancedProgressIndicator()
            : _buildProgressPlaceholder(),
      ],
    );
  }

  Widget _buildEnhancedProgressIndicator() {
    final infoDasar = _setoranData!.setoran.infoDasar;
    final progress = infoDasar.persentaseProgresSetor;
    final progressColor = _getProgressColor(progress);
    final completedCount = infoDasar.totalSudahSetor;
    final totalCount = infoDasar.totalWajibSetor;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar dengan animasi
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.white.withOpacity(0.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    // Progress fill dengan gradient
                    FractionallySizedBox(
                      widthFactor: (progress / 100) * _progressAnimation.value,
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              progressColor.withOpacity(0.8),
                              progressColor,
                              progressColor.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    // Shimmer effect
                    if (progress > 0 && _progressAnimation.value > 0.5)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pulseAnimationController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(
                                        0.3 * _pulseAnimation.value),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Progress info dengan animasi
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Progress percentage
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    final animatedProgress = progress *
                        _progressAnimation.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        //borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: progressColor.withOpacity(
                            0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getProgressIcon(progress),
                            color: progressColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${animatedProgress.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 16,
                              color: progressColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                // Progress count
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    //borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.book,
                        color: Colors.white.withOpacity(0.9),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          final animatedCompleted = (completedCount *
                              _progressAnimation.value).round();
                          return Text(
                            '$animatedCompleted/$totalCount',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress message
            //_buildProgressMessage(progress),
          ],
        );
      },
    );
  }

  // Opsional
  // Widget _buildProgressMessage(double progress) {
  //   String message;
  //   Color messageColor;
  //   IconData messageIcon;
  //
  //   if (progress == 0) {
  //     message = "Yuk mulai setoran pertama!";
  //     messageColor = Colors.red.shade300;
  //     messageIcon = Icons.play_arrow;
  //   } else if (progress < 25) {
  //     message = "Semangat! Terus lanjutkan!";
  //     messageColor = Colors.orange.shade300;
  //     messageIcon = Icons.trending_up;
  //   } else if (progress < 50) {
  //     message = "Bagus! Sudah seperempat jalan!";
  //     messageColor = Colors.yellow.shade300;
  //     messageIcon = Icons.star_half;
  //   } else if (progress < 75) {
  //     message = "Hebat! Sudah setengah perjalanan!";
  //     messageColor = Colors.blue.shade300;
  //     messageIcon = Icons.favorite;
  //   } else if (progress < 100) {
  //     message = "Luar biasa! Hampir selesai!";
  //     messageColor = Colors.lightGreen.shade300;
  //     messageIcon = Icons.emoji_events;
  //   } else {
  //     message = "Alhamdulillah! Setoran lengkap!";
  //     messageColor = Colors.green.shade300;
  //     messageIcon = Icons.celebration;
  //   }
  //
  //   return AnimatedBuilder(
  //     animation: _pulseAnimationController,
  //     builder: (context, child) {
  //       return Transform.scale(
  //         scale: progress >= 100 ? _pulseAnimation.value : 1.0,
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //           child: Row(
  //             children: [
  //               Icon(
  //                 messageIcon,
  //                 color: messageColor,
  //                 size: 16,
  //               ),
  //               const SizedBox(width: 6),
  //               Text(
  //                 message,
  //                 style: TextStyle(
  //                   fontSize: 13,
  //                   color: messageColor,
  //                   fontWeight: FontWeight.w600,
  //                   fontStyle: FontStyle.italic,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildProgressPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skeleton loading untuk progress bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.white.withOpacity(0.3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.3 * _pulseAnimation.value),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Memuat progress...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getProgressIcon(double progress) {
    if (progress == 0) return Icons.play_arrow;
    if (progress < 25) return Icons.trending_up;
    if (progress < 50) return Icons.star_half;
    if (progress < 75) return Icons.favorite;
    if (progress < 100) return Icons.emoji_events;
    return Icons.celebration;
  }

  Color _getProgressColor(double progress) {
    if (progress == 0) return Colors.red.shade400;
    if (progress < 25) return Colors.orange.shade400;
    if (progress < 50) return Colors.yellow.shade600;
    if (progress < 75) return Colors.blue.shade400;
    if (progress < 100) return Colors.lightGreen.shade500;
    return Colors.green.shade500;
  }

  Widget _buildAvatarImage() {
    return Container(
      width: 100,
      height: 147,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/orang.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Constants.primaryColor,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          child: Column(
            children: [
              _buildSearchBar(),
              _buildTabBar(),
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Cari surah',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Constants.primaryColor,
      labelColor: Constants.primaryColor,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(text: 'Surah'),
        Tab(text: 'Belum Disetor'),
        Tab(text: 'Sudah Disetor'),
      ],
    );
  }

  Widget _buildTabContent() {
    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredSurahs.isEmpty
          ? _buildEmptyState()
          : _buildSurahList(),
    );
  }

  Widget _buildSurahList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSurahs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final surah = _filteredSurahs[index];
        return _buildSurahItem(surah);
      },
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Constants.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.3,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada data',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahItem(SurahModel surah) {
    final String stageLabel = _getStageLabel(surah.label);
    final Color stageColor = _getStageColor(surah.label);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showSurahDetails(surah),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: surah.sudahSetor ? Colors.green : Colors.red,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          surah.sudahSetor ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: surah.sudahSetor ? Colors.green : Colors
                              .orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          surah.sudahSetor ? 'Sudah Disetor' : 'Belum Disetor',
                          style: TextStyle(
                            fontSize: 12,
                            color: surah.sudahSetor ? Colors.green : Colors
                                .orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: stageColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stageLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStageColor(String code) {
    switch (code) {
      case 'KP':
        return Colors.blueAccent;
      case 'SEMKP':
        return Colors.teal;
      case 'DAFTAR_TA':
        return Colors.amber;
      case 'SEMPRO':
        return Colors.deepOrange;
      case 'SIDANG_TA':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _getStageLabel(String code) {
    return Constants.labelMap[code] ?? code;
  }
}