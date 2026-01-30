import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/sigil_storage_service.dart';
import '../models/saved_sigil.dart';
import 'sigil_detail_screen.dart';
import 'account_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SigilStorageService _storageService = SigilStorageService();
  List<SavedSigil> _sigils = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSigils();
  }

  Future<void> _loadSigils() async {
    setState(() {
      _isLoading = true;
    });
    final sigils = await _storageService.loadSigils();
    // Sort by date descending (newest first)
    sigils.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
    if (mounted) {
      setState(() {
        _sigils = sigils;
        _isLoading = false;
      });
    }
  }

  // Refresh when returning from creation screen
  void _navigateAndRefresh() async {
    await Navigator.pushNamed(context, '/create-sigil');
    _loadSigils();
  }

  void _openDetail(SavedSigil sigil) async {
    final deleted = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SigilDetailScreen(sigil: sigil)),
    );

    if (deleted == true) {
      _loadSigils();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sigils.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Grimoire is empty',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Create your first Sigil to begin.'),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _sigils.length,
              itemBuilder: (context, index) {
                final sigil = _sigils[index];
                return _buildSigilCard(sigil);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndRefresh,
        label: const Text('New Sigil'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSigilCard(SavedSigil sigil) {
    return GestureDetector(
      onTap: () => _openDetail(sigil),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // border side removed as requested
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.file(
                File(sigil.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sigil.incantation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
