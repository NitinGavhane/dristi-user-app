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

    // Read the policy through `promoLine`, never off `fee` alone: a seller who
    // switches charging off in the Admin app keeps the amount saved for later,
    // so a bare `fee > 0` test kept announcing a charge the checkout no longer
    // applies. `promoLine` weighs `enabled` too, and says so when it is free.
    final message = settings.promoLine;

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
