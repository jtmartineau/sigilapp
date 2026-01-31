import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../models/saved_sigil.dart';
import '../services/sigil_storage_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class SigilDetailScreen extends StatelessWidget {
  final SavedSigil sigil;
  final SigilStorageService _storageService = SigilStorageService();

  SigilDetailScreen({super.key, required this.sigil});

  Future<void> _handleBurn(BuildContext context) async {
    // 1. Show Animation (Placeholder)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Burning sigil... 🔥')));

    // Attempt to notify backend
    try {
      final token = context.read<AuthService>().token;
      // Use LocationService
      final position = await LocationService().getCurrentLocation(context);

      final file = File(sigil.imagePath);
      if (await file.exists()) {
        await ApiService().uploadSigil(
          sigil.incantation,
          file,
          true, // isBurned
          token,
          lat: position?.latitude,
          long: position?.longitude,
          burnedLat: position?.latitude,
          burnedLong: position?.longitude,
        );
        debugPrint('Sigil burn uploaded successfully.');
      }
    } catch (e) {
      debugPrint('Error uploading burned sigil: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offline burn (sync failed): $e')),
        );
      }
    }

    await Future.delayed(const Duration(seconds: 2));

    // 2. Delete from Storage
    await _storageService.deleteSigil(sigil.id);

    // 3. Delete the local file (optional, but good hygiene)
    try {
      final file = File(sigil.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
    }

    if (context.mounted) {
      Navigator.pop(context, true); // Return true to indicate deletion
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      await Share.shareXFiles([
        XFile(sigil.imagePath),
      ], text: 'My Sigil: ${sigil.incantation}');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(File(sigil.imagePath), fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '"${sigil.incantation}"',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF6A1B9A), // Deep Purple
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 20,
              runSpacing: 10,
              children: [
                TextButton.icon(
                  onPressed: () => _handleBurn(context),
                  icon: const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFC5A000),
                  ),
                  label: const Text(
                    'DIGITALLY BURN',
                    style: TextStyle(
                      color: Color(0xFFC5A000),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _handleShare(context),
                  icon: const Icon(Icons.share, color: Color(0xFFC5A000)),
                  label: const Text(
                    'SHARE',
                    style: TextStyle(
                      color: Color(0xFFC5A000),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Back to Dashboard',
                style: TextStyle(
                  color: Color(0xFFC5A000),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
