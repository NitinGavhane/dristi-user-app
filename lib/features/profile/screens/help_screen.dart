import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  static const String _supportPhone = '+916290486090';
  static const String _whatsappNumber = '916290486090';
  final List<Map<String, dynamic>> _faqs = [
    {'q': 'How do I track my order?', 'expanded': false, 'a': 'Go to Orders section in your profile and tap on the order you want to track. You can see the live tracking status there.'},
    {'q': 'What is the return policy?', 'expanded': false, 'a': 'We offer 7-day return policy on all products. Items must be unused and in original packaging.'},
    {'q': 'How long does delivery take?', 'expanded': false, 'a': 'Standard delivery takes 3-5 business days. Express delivery is available in 1-2 business days.'},
    {'q': 'What payment methods are accepted?', 'expanded': false, 'a': 'We accept UPI (Google Pay, PhonePe, Paytm), Credit/Debit Cards, Net Banking, and Cash on Delivery.'},
  ];

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showUnavailable('No calling app found on this device.');
      }
    } catch (_) {
      _showUnavailable('Could not open the dialer right now.');
    }
  }

  Future<void> _chatSupport() async {
    // Opens WhatsApp with a pre-filled message so the shopper only has to hit
    // send. If WhatsApp is not installed this falls back to the web client.
    final message = Uri.encodeComponent(
        'Hi Dristi Fashions! I need help with my order.');
    final uri = Uri.parse('https://wa.me/$_whatsappNumber?text=$message');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showUnavailable('Could not open WhatsApp. Please try again.');
      }
    } catch (_) {
      _showUnavailable('Could not open WhatsApp right now.');
    }
  }

  void _showUnavailable(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support', style: AppTextStyles.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need help?', style: AppTextStyles.headline2.copyWith(color: AppColors.white)),
                  const SizedBox(height: 8),
                  Text('We\'re here to help you 24/7', style: AppTextStyles.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _contactButton(Iconsax.call, 'Call Us', _callSupport),
                      const SizedBox(width: 12),
                      _contactButton(Iconsax.message, 'Chat', _chatSupport),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text('Frequently Asked Questions', style: AppTextStyles.subtitle),
            const SizedBox(height: AppDimensions.sm),
            ..._faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Text(faq['q'] as String, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                initiallyExpanded: faq['expanded'] as bool,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(faq['a'] as String, style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _contactButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
