import 'package:flutter/material.dart';
import '../constants.dart';

class AuthDialogs {
  static Future<bool> showTokenExpiredDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Sesi Berakhir',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Sesi login Anda telah berakhir. Apakah Anda ingin memperpanjang sesi atau keluar?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text('Keluar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Perpanjang Sesi'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  static Future<bool> showSessionExpiredDialog(BuildContext context, {required bool canRefresh}) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                canRefresh ? Icons.access_time : Icons.error_outline,
                color: canRefresh ? Colors.orange : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                canRefresh ? 'Sesi Akan Berakhir' : 'Sesi Berakhir',
                style: TextStyle(
                  color: canRefresh ? Colors.orange : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canRefresh
                    ? 'Sesi login Anda akan segera berakhir.'
                    : 'Sesi login Anda telah berakhir sepenuhnya.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (canRefresh) ...[
                const Text(
                  'Apakah Anda ingin memperpanjang sesi?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pilih "Ya" untuk melanjutkan atau "Tidak" untuk abaikan.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'Silakan login kembali untuk melanjutkan.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          actions: [
            if (canRefresh) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                child: const Text('Tidak'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya, Perpanjang'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login Ulang'),
              ),
            ],
          ],
        );
      },
    ) ?? false;
  }
}