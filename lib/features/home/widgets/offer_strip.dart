import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/delivery_provider.dart';

class OfferStrip extends StatelessWidget {
  const OfferStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final delivery = context.watch<DeliveryProvider>();
    final settings = delivery.settings;

    if (settings.fee <= 0) {
      return const SizedBox.shrink();
    }

    final message = settings.freeAbove != null && settings.freeAbove! > 0
        ? 'Complimentary delivery on orders above \u20B9${settings.freeAbove!.toStringAsFixed(0)}'
        : settings.hasStateFees
            ? 'Delivery from \u20B9${settings.minimumFee.toStringAsFixed(0)} · by state'
            : 'Flat \u20B9${settings.fee.toStringAsFixed(0)} delivery, anywhere in India';

    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.truck, size: 14, color: AppColors.festiveGold),
          const SizedBox(width: 6),
          Text(
            message.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.brandGoldLight,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
