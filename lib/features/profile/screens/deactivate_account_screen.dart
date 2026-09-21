import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';

/// Deactivation — the reversible door out.
///
/// Nothing is erased here. The screen's job is to make that unmistakable, so
/// that someone who only wants a break does not reach for [DeleteAccountScreen]
/// instead. The confirmation code is requested the moment the screen opens,
/// which is why the field simply says "Enter received OTP".
class DeactivateAccountScreen extends StatefulWidget {
  const DeactivateAccountScreen({super.key});

  @override
  State<DeactivateAccountScreen> createState() => _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState extends State<DeactivateAccountScreen> {
  final _otpController = TextEditingController();
  bool _sending = true;
  bool _sent = false;

  static const _effects = [
    'You are logged out of your Dristi Fashions account.',
    'Your profile is no longer visible on the store.',
    'Your reviews and ratings stay, but your name is shown as '
        '‘Unavailable’.',
    'Your wishlist is no longer accessible and is shown as '
        '‘Unavailable’.',
    'You are unsubscribed from our promotional emails.',
    'Your account data is retained, and is restored if you choose to '
        'reactivate your account.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() => _sending = true);
    final ok = await context.read<AuthProvider>().sendDeactivationOtp();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = ok;
    });
    if (ok) {
      final email = context.read<AuthProvider>().user?.email ?? 'your email';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Confirmation code sent to $email')),
      );
    }
  }

  Future<void> _confirm() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code we emailed you')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.deactivateAccount(otp: otp);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not deactivate your account')),
      );
      return;
    }

    // The session is already gone; drop the in-memory bag too, the same way
    // signing out does, so the next shopper on this device starts clean.
    context.read<CartProvider>().clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your account has been deactivated. Sign in again to restore it.'),
        duration: Duration(seconds: 4),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('Deactivate Account', style: AppTextStyles.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Are you sure you want to leave?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),

            _card(
              title: 'When you deactivate your account',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _effects.map(_bullet).toList(),
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            _card(
              title: 'How do I reactivate my account?',
              child: Text(
                'Reactivation is easy. Simply sign in with the email address and '
                'password you used before deactivating. Your account data is fully '
                'restored, default settings are applied, and you are subscribed to '
                'receive promotional emails again.',
                style: AppTextStyles.bodySmall.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),

            if (user != null) ...[
              Text(user.email, style: AppTextStyles.body),
              if (user.phone != null && user.phone!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(user.phone!, style: AppTextStyles.body),
                ),
              const SizedBox(height: AppDimensions.md),
            ],

            Text('Enter received OTP', style: AppTextStyles.subtitle),
            const SizedBox(height: AppDimensions.sm),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 10,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _sending ? null : _sendOtp,
                child: Text(
                  _sending
                      ? 'Sending code…'
                      : _sent
                          ? 'Resend code'
                          : 'Send code',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                child: Text(
                  auth.error!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ),

            const SizedBox(height: AppDimensions.md),
            AppButton(
              label: 'CONFIRM DEACTIVATION',
              onPressed: auth.isLoading ? null : _confirm,
              isLoading: auth.isLoading,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'NO, LET ME STAY!',
              onPressed: () => Navigator.pop(context),
              isOutline: true,
            ),
            const SizedBox(height: AppDimensions.xxl),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subtitle),
          const SizedBox(height: AppDimensions.sm),
          child,
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3, right: 8),
            child: Icon(Iconsax.minus, size: 14, color: AppColors.textMuted),
          ),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall.copyWith(height: 1.5)),
          ),
        ],
      ),
    );
  }
}
