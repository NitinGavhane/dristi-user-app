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
import 'deactivate_account_screen.dart';

/// Deletion — the permanent door out.
///
/// Deliberately slower than deactivation: the account has to be clear of
/// unfinished business, all three acknowledgements have to be ticked, and a
/// code emailed to the registered address has to be typed back in. Anyone who
/// only wants a pause is pointed at [DeactivateAccountScreen] first.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _reasonController = TextEditingController();
  final _otpController = TextEditingController();

  bool _checkingEligibility = true;
  bool _canDelete = false;
  List<String> _blockers = const [];

  bool _acceptedTerms = false;
  bool _acknowledgedBalance = false;
  bool _acknowledgedNoReturns = false;

  bool _otpSent = false;

  static const _conditions = [
    'There are no pending orders, cancellations, returns, refunds or other '
        'requests. If there are, please raise your deletion request once they '
        'are completed.',
    'You have exhausted, or do not intend to use, your Dristi Wallet balance '
        'and any referral rewards. Once your account is deleted you will not '
        'be able to access them.',
    'You will not be able to access order history, your profile, wishlist, '
        'saved addresses, previous orders and invoices, or use any of the '
        'products and services we offer, immediately on deletion. You will '
        'have to create a new account to shop with us again.',
    'We may refuse deletion of your account if you have a legal dispute, or '
        'a grievance related to pending payments, orders, shipments or '
        'deliveries.',
    'We may retain certain data for legitimate reasons — security, fraud '
        'prevention and regulatory compliance, including tax invoices we are '
        'required by law to keep.',
    'After your account is deleted, signing in with the same phone number or '
        'email address creates a fresh new account. Your old account data '
        'will not be accessible in it.',
    'Please uninstall the app after your account is deleted to stop receiving '
        'notifications. Notifications are an app-level setting, so uninstalling '
        'the app is required to stop all of them.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEligibility());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadEligibility() async {
    final result = await context.read<AuthProvider>().fetchDeletionEligibility();
    if (!mounted) return;
    setState(() {
      _checkingEligibility = false;
      _canDelete = result?['can_delete'] as bool? ?? false;
      _blockers = ((result?['blockers'] as List<dynamic>?) ?? [])
          .map((b) => (b as Map<String, dynamic>)['message'] as String? ?? '')
          .where((m) => m.isNotEmpty)
          .toList();
    });
  }

  bool get _allAcknowledged =>
      _acceptedTerms && _acknowledgedBalance && _acknowledgedNoReturns;

  Future<void> _requestOtp() async {
    if (!_allAcknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tick all three acknowledgements first')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendDeletionOtp();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not send the confirmation code')),
      );
      return;
    }

    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Confirmation code sent to ${auth.user?.email ?? 'your email'}'),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code we emailed you')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete your account?', style: AppTextStyles.title),
        content: Text(
          'This is permanent. Your account cannot be restored under any '
          'circumstances, and your order history will no longer be accessible.',
          style: AppTextStyles.bodySmall.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete Permanently',
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.deleteAccount(
      otp: otp,
      reason: _reasonController.text.trim(),
      acceptedTerms: _acceptedTerms,
      acknowledgedBalanceForfeit: _acknowledgedBalance,
      acknowledgedNoReturns: _acknowledgedNoReturns,
    );
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not delete your account')),
      );
      return;
    }

    context.read<CartProvider>().clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your account has been permanently deleted.'),
        duration: Duration(seconds: 4),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('Delete Account', style: AppTextStyles.title)),
      body: _checkingEligibility
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'We are sorry to see you go!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Once you choose to delete your account, it will no longer be '
                    'available to you and you will not be able to activate, restore '
                    'or use it again.',
                    style: AppTextStyles.bodySmall.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  _deactivateInstead(),
                  const SizedBox(height: AppDimensions.lg),

                  if (_blockers.isNotEmpty) ...[
                    _blockerCard(),
                    const SizedBox(height: AppDimensions.lg),
                  ],

                  _card(
                    title: 'Please read and understand the following',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _conditions.map(_bullet).toList(),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Iconsax.warning_2, size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(
                              'Deleting your account is permanent',
                              style: AppTextStyles.subtitle.copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        Text(
                          'Once your account is deleted you will lose your Dristi '
                          'Fashions data, including your order history. It will no '
                          'longer be accessible and cannot be restored under any '
                          'circumstances.',
                          style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  _checkbox(
                    value: _acceptedTerms,
                    onChanged: (v) => setState(() => _acceptedTerms = v),
                    label: 'I have read and agreed to the Terms and Conditions.',
                  ),
                  _checkbox(
                    value: _acknowledgedBalance,
                    onChanged: (v) => setState(() => _acknowledgedBalance = v),
                    label: 'I acknowledge that I do not have any Dristi Wallet '
                        'balance or referral rewards in my account, or I am willing '
                        'to forfeit any such balance available in my account.',
                  ),
                  _checkbox(
                    value: _acknowledgedNoReturns,
                    onChanged: (v) => setState(() => _acknowledgedNoReturns = v),
                    label: 'I acknowledge that I will not be able to return or '
                        'replace, or seek any service regarding, any past order or '
                        'transaction.',
                  ),
                  const SizedBox(height: AppDimensions.md),

                  Text('Please tell us why you’re leaving us',
                      style: AppTextStyles.subtitle),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    maxLength: 500,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Your reason (optional, but it helps us improve)',
                      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
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

                  if (_otpSent) ...[
                    const SizedBox(height: AppDimensions.sm),
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
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.isLoading ? null : _requestOtp,
                        child: Text(
                          'Resend code',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.sm),
                      child: Text(
                        auth.error!,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                      ),
                    ),

                  const SizedBox(height: AppDimensions.lg),
                  AppButton(
                    label: _otpSent ? 'DELETE ACCOUNT' : 'CONTINUE',
                    onPressed: (!_canDelete || !_allAcknowledged || auth.isLoading)
                        ? null
                        : (_otpSent ? _confirmDelete : _requestOtp),
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

  Widget _deactivateInstead() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Not sure? Deactivate instead', style: AppTextStyles.subtitle),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Deactivating logs you out, hides your profile, makes your wishlist '
            'unreachable and unsubscribes you from promotional emails — but '
            'nothing is erased. Sign in again any time and everything comes back.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppDimensions.sm),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DeactivateAccountScreen()),
            ),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
              'Deactivate my account instead',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.info_circle, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your account cannot be deleted yet',
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ..._blockers.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(b, style: AppTextStyles.bodySmall.copyWith(height: 1.5)),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _checkbox({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String label,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
