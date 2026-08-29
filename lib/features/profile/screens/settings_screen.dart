import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import 'edit_profile_screen.dart';
import 'address_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account', style: AppTextStyles.subtitle),
            const SizedBox(height: AppDimensions.sm),
            _settingTile(Iconsax.user, 'Personal Information', 'Edit your name, email, phone', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
            _settingTile(Iconsax.home_2, 'Address', 'Manage your saved addresses', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen()))),
            const SizedBox(height: AppDimensions.lg),
            Text('Preferences', style: AppTextStyles.subtitle),
            const SizedBox(height: AppDimensions.sm),
            _switchTile(Iconsax.notification, 'Push Notifications', _notifications, (v) => setState(() => _notifications = v)),
            const SizedBox(height: AppDimensions.lg),
            Text('More', style: AppTextStyles.subtitle),
            const SizedBox(height: AppDimensions.sm),
            _settingTile(Iconsax.info_circle, 'About', 'Version 1.0.0'),
          ],
        ),
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
        title: Text(title, style: AppTextStyles.body),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
        title: Text(title, style: AppTextStyles.body),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
