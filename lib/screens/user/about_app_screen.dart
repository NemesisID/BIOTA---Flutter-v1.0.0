import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:biota_2/constants/colors.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar dengan Gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // App Logo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/logo/logo.png',
                          height: 60,
                          width: 60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BIOTA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Biodiversity Tracker & Awareness',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // App Info Card
                _buildInfoCard(
                  title: 'Informasi Aplikasi',
                  children: [
                    _buildInfoRow(Icons.info, 'Versi', '0.1.1'),
                    _buildInfoRow(Icons.build, 'Build', '2025.06.13'),
                    _buildInfoRow(Icons.android, 'Platform', 'Android'),
                    _buildInfoRow(Icons.language, 'Bahasa', 'Indonesia'),
                  ],
                ),

                const SizedBox(height: 16),

                // About Description Card
                _buildDescriptionCard(),

                const SizedBox(height: 16),

                // Features Card
                _buildFeaturesCard(),

                const SizedBox(height: 16),

                // Developer Team Card
                _buildDeveloperCard(),

                const SizedBox(height: 16),

                // Contact & Support Card
                _buildContactCard(context),

                const SizedBox(height: 16),

                // Credits Card
                _buildCreditsCard(),

                const SizedBox(height: 32),

                // Footer
                _buildFooter(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nature, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Tentang BIOTA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'BIOTA adalah aplikasi mobile yang dirancang untuk membantu pelestarian biodiversitas Indonesia. Aplikasi ini memungkinkan pengguna untuk mendokumentasikan, berbagi, dan mempelajari tentang flora dan fauna di sekitar mereka.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Dengan BIOTA, setiap orang dapat menjadi kontributor dalam upaya konservasi dan perlindungan keanekaragaman hayati Indonesia.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final features = [
      {'icon': Icons.camera_alt, 'title': 'Dokumentasi Spesies', 'desc': 'Ambil foto dan catat informasi spesies'},
      {'icon': Icons.map, 'title': 'Peta Interaktif', 'desc': 'Jelajahi lokasi spesies di sekitar Anda'},
      {'icon': Icons.event, 'title': 'Event Konservasi', 'desc': 'Ikuti kegiatan pelestarian lingkungan'},
      {'icon': Icons.people, 'title': 'Komunitas', 'desc': 'Bergabung dengan para pecinta alam'},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: AppColors.accent, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Fitur Utama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          feature['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Tim Pengembang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDeveloperInfo(
              'Developer',
              'Tim BIOTA',
              'RAGIL HIDAYATULLOH (23082010014)',
              Icons.person,
            ),
            const SizedBox(height: 12),
            _buildDeveloperInfo(
              'UI/UX Designer',
              'Tim Design BIOTA',
              'ANNISA INDAH CAHYANI (23082010028)',
              Icons.design_services,
            ),
            const SizedBox(height: 12),
            _buildDeveloperInfo(
              'Content Creator',
              'Tim Konten BIOTA',
              'DEBITA FAULIRISMA GARCIA (23082010027)',
              Icons.edit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo(String role, String name, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                role,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_support, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Kontak & Dukungan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.email,
              'Email',
              'support@biota.app',
              () => _launchEmail('support@biota.app'),
            ),
            _buildContactItem(
              Icons.web,
              'Website',
              'www.biota.app',
              () => _launchURL('https://www.biota.app'),
            ),
            _buildContactItem(
              Icons.bug_report,
              'Laporkan Bug',
              'Kirim laporan masalah',
              () => _showFeedbackDialog(context),
            ),
            _buildContactItem(
              Icons.star_rate,
              'Rating & Review',
              'Beri penilaian di Play Store',
              () => _launchURL('https://play.google.com/store'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Terima Kasih',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi ini tidak akan ada tanpa dukungan dari:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _buildCreditItem('Flutter Framework', 'Google'),
            _buildCreditItem('OpenStreetMap', 'OSM Community'),
            _buildCreditItem('Material Design', 'Google'),
            _buildCreditItem('WWF Indonesia', 'Data Konservasi'),
            _buildCreditItem('LIPI', 'Database Spesies'),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditItem(String name, String provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$name - $provider',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo/logo.png',
                height: 24,
                width: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'BIOTA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dibuat Dengan ❤️ Untuk Indonesia\'s Biodiversity',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '© 2025 BIOTA Team. All rights reserved.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      print('Could not launch $url');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    if (!await launchUrl(uri)) {
      print('Could not launch email');
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporkan Bug'),
        content: const Text(
          'Untuk melaporkan bug atau memberikan feedback, silakan kirim email ke support@biota.app dengan detail masalah yang Anda alami.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchEmail('support@biota.app');
            },
            child: const Text('Kirim Email'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kebijakan Privasi'),
        content: const SingleChildScrollView(
          child: Text(
            'BIOTA berkomitmen untuk melindungi privasi pengguna. Kami hanya mengumpulkan data yang diperlukan untuk memberikan layanan terbaik dan tidak akan membagikan informasi pribadi Anda kepada pihak ketiga tanpa persetujuan.\n\n'
            'Data yang kami kumpulkan:\n'
            '• Informasi profil pengguna\n'
            '• Data spesies yang dikirimkan\n'
            '• Lokasi untuk fitur pemetaan\n'
            '• Data penggunaan aplikasi\n\n'
            'Semua data disimpan dengan aman dan dienkripsi.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Syarat & Ketentuan'),
        content: const SingleChildScrollView(
          child: Text(
            'Dengan menggunakan aplikasi BIOTA, Anda menyetujui syarat dan ketentuan berikut:\n\n'
            '1. Penggunaan aplikasi harus untuk tujuan yang positif dan mendukung konservasi\n'
            '2. Data yang dikirimkan harus akurat dan tidak menyesatkan\n'
            '3. Dilarang mengirimkan konten yang melanggar hukum\n'
            '4. Kami berhak menghapus konten yang tidak sesuai\n'
            '5. Aplikasi disediakan "sebagaimana adanya"\n\n'
            'Syarat lengkap dapat dilihat di website kami.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keamanan Data'),
        content: const SingleChildScrollView(
          child: Text(
            'Keamanan data Anda adalah prioritas kami:\n\n'
            '• Enkripsi end-to-end untuk semua data\n'
            '• Server yang aman dan terpercaya\n'
            '• Backup rutin untuk mencegah kehilangan data\n'
            '• Autentikasi berlapis untuk akses admin\n'
            '• Monitoring keamanan 24/7\n\n'
            'Jika Anda menemukan masalah keamanan, segera laporkan kepada kami.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}