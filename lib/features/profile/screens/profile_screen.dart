import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../orders/screens/order_list_screen.dart';
import '../../wishlist/screens/wishlist_screen.dart';
import 'wallet_screen.dart';
import 'referral_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';
import 'change_password_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'loyalty_program_screen.dart';
import 'faq_screen.dart';
import '../../auth/screens/register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final user = auth.user;

        if (user == null) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBg,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.divider,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.user, size: 40, color: AppColors.textHint),
                      ),
                      const SizedBox(height: AppDimensions.lg),
                      Text(
                        'Sign in to your account',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Text(
                        'Access your orders, wishlist & more',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xxl),
                      AppButton(
                        label: 'SIGN IN',
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'CREATE ACCOUNT',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        isOutline: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppBar(
            title: Text(
              'My Account',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.brandGoldLight,
              ),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.festiveGold,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.brandGoldLight, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            user.fullName.split(' ').map((n) => n[0].toUpperCase()).join(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.brandGoldLight,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _statBadge(
                            '${context.watch<OrderProvider>().count}',
                            'Orders',
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: AppColors.brandGoldLight.withValues(alpha: 0.3),
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          _statBadge(
                            '${context.watch<WishlistProvider>().count}',
                            'Wishlist',
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: AppColors.brandGoldLight.withValues(alpha: 0.3),
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          _statBadge(
                            '₹${user.walletBalance.toStringAsFixed(0)}',
                            'Wallet',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Column(
                    children: [
                      _menuItem(
                        icon: Iconsax.box,
                        title: 'My Orders',
                        count: '${context.watch<OrderProvider>().count}',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OrderListScreen()),
                        ),
                      ),
                      _menuItem(
                        icon: Iconsax.heart,
                        title: 'My Wishlist',
                        count: '${context.watch<WishlistProvider>().count}',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WishlistScreen()),
                        ),
                      ),
                      _menuItem(
                        icon: Iconsax.wallet,
                        title: 'Dristi Wallet',
                        subtitle: '₹${user.walletBalance.toStringAsFixed(2)}',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletScreen()),
                        ),
                      ),
                      _menuItem(
                        icon: Iconsax.profile_2user,
                        title: 'Refer & Earn',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReferralScreen()),
                        ),
                      ),
                      _menuItem(
                        icon: Iconsax.setting,
                        title: 'Settings',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                      _menuItem(
                        icon: Iconsax.lock,
                        title: 'Change Password',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        ),
                      ),
                      _menuItem(
                        icon: Iconsax.info_circle,
                        title: 'Help',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HelpScreen()),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          'POLICIES',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      _menuItem(
                        icon: Iconsax.crown,
                        title: 'Drishti Rewards & Club',
                        subtitle: 'Loyalty program',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoyaltyProgramScreen()),
                        ),
                      ),
                      _menuItem(
                        icon: Iconsax.shield_tick,
                        title: 'Privacy Policy',
                        subtitle: 'Your data & rights',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        ),
                      ),
                      _menuItem(
                        icon: Iconsax.document_text,
                        title: 'Terms & Conditions',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                        ),
                      ),
                      _menuItem(
                        icon: Iconsax.message_question,
                        title: 'FAQ',
                        subtitle: 'Frequently asked questions',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FaqScreen()),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.lg),
                      AppButton(
                        label: 'SIGN OUT',
                        onPressed: () {
                          auth.logout();
                          context.read<CartProvider>().clear();
                          Navigator.pushReplacementNamed(context, '/main');
                        },
                        isOutline: true,
                      ),
                      const SizedBox(height: AppDimensions.xxl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statBadge(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.brandGoldLight,
          ),
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    String? count,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle != null)
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.festiveGold,
                ),
              ),
            if (count != null) ...[
              Text(
                count,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        onTap: onTap,
      ),
    );
  }
}
