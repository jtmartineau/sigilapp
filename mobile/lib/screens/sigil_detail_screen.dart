import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../models/saved_sigil.dart';
import '../services/sigil_storage_service.dart';

class SigilDetailScreen extends StatelessWidget {
  final SavedSigil sigil;
  final SigilStorageService _storageService = SigilStorageService();

  SigilDetailScreen({super.key, required this.sigil});

  Future<void> _handleBurn(BuildContext context) async {
    // 1. Show Animation (Placeholder)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Burning sigil... 🔥')));
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
        title: const Text('Sigil Detail'),
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
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(File(sigil.imagePath), fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              sigil.incantation,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Created on: ${sigil.dateCreated.toString().split(' ')[0]}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleBurn(context),
                  icon: const Icon(Icons.local_fire_department),
                  label: const Text('DIGITALLY BURN'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleShare(context),
                  icon: const Icon(Icons.share),
                  label: const Text('SHARE'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
