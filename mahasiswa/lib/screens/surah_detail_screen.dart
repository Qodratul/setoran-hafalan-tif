import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/surah_model.dart';

class SurahDetailScreen extends StatelessWidget {
  final SurahModel surah;

  const SurahDetailScreen({Key? key, required this.surah}) : super(key: key);

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return '-';

      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSubmitted = surah.sudahSetor;
    final infoSetoran = surah.infoSetoran;

    return Scaffold(
      appBar: AppBar(
        title: Text(surah.nama),
        backgroundColor: Constants.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
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
        child: Column(
          children: [
            // Surah Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        surah.nama,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSubmitted ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSubmitted ? 'Sudah Disetor' : 'Belum Disetor',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Constants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tahap: ${Constants.labelMap[surah.label] ?? surah.label}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Constants.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Status Details
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isSubmitted && infoSetoran != null
                    ? _buildSubmittedDetails(context)
                    : _buildUnsubmittedDetails(context),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedDetails(BuildContext context) {
    final infoSetoran = surah.infoSetoran!;
    final dosenPengesah = infoSetoran.dosenYangMengesahkan;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Setoran',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Constants.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('ID Setoran', infoSetoran.id),
          const Divider(),
          _buildInfoRow('Tanggal Setoran', _formatDate(infoSetoran.tglSetoran)),
          const Divider(),
          _buildInfoRow('Tanggal Validasi', _formatDate(infoSetoran.tglValidasi)),
          const Divider(),
          const Text(
            'Dosen Pengesah',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Constants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Constants.primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dosenPengesah.nama,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIP: ${dosenPengesah.nip}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email: ${dosenPengesah.email}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement document printing or sharing
              },
              icon: const Icon(Icons.download),
              label: const Text('Download Bukti Setoran'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsubmittedDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Disetor',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Constants.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Surah ini belum disetor. Silahkan temui dosen pembimbing untuk melakukan setoran hafalan.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Kembali'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}