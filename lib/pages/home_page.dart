import 'package:flutter/material.dart';
import 'package:safe_allergy/pages/auth_page.dart';
import 'package:safe_allergy/pages/nfc_read_page.dart';
import 'package:safe_allergy/pages/qr_read_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 30),
              Image.asset('assets/images/logoo.png', height: 120),
              const SizedBox(height: 20),
              Text(
                'Emergency Patient Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E658F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 100),
              _buildActionCard(
                context,
                icon: Icons.nfc,
                title: 'Read NFC / QR',
                subtitle: 'Scan patient data',
                color: Colors.green,
                onTap: () => _showReadOptions(context),
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context,
                icon: Icons.edit,
                title: 'Write NFC',
                subtitle: 'Write patient data to NFC',
                color: Colors.blue,
                onTap: () => _navigateToWrite(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      color: Color.fromARGB(255, 241, 248, 252),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E658F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Color.fromARGB(255, 36, 96, 142),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.nfc, color: Colors.blue),
              title: Text(
                'Read from NFC Tag',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2E658F),
                  fontSize: 18,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NfcReadPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.green),
              title: Text(
                'Scan QR Code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2E658F),
                  fontSize: 18,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrReadPage()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToWrite(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }
}
