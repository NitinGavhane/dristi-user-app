import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

class FaqItem {
  const FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class FaqCategory {
  const FaqCategory({required this.heading, required this.items});
  final String heading;
  final List<FaqItem> items;
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<FaqCategory> _categories = [
    FaqCategory(heading: '1. Orders & Tracking', items: [
      FaqItem(
        question: 'How do I place an order on Drishti Fashions?',
        answer:
            'Simply browse our collection, select your preferred size and colour, tap "Add to Bag," and proceed to checkout. Enter your shipping address and choose your preferred payment method to complete your purchase.',
      ),
      FaqItem(
        question: 'Can I modify or cancel my order?',
        answer:
            'You can cancel your order within 24 hours of placing it by going to the "My Orders" section in your account or by contacting customer support. Once dispatched, orders cannot be modified or cancelled.',
      ),
      FaqItem(
        question: 'How can I track my order?',
        answer:
            'Once your order is shipped, tracking details become active within 24 hours. You can view the live status of your package anytime by visiting the "My Orders" section in the app or website.',
      ),
      FaqItem(
        question: 'Why has my order been split into multiple shipments?',
        answer:
            'If you ordered multiple items, they may be shipped from different partner warehouses or fulfilment centres to reach you as quickly as possible. You will receive tracking details for each individual shipment.',
      ),
    ]),
    FaqCategory(heading: '2. Shipping & Delivery', items: [
      FaqItem(
        question: 'How much are the shipping charges?',
        answer:
            'We charge a transparent Convenience Fee which includes a flat platform fee of ₹29, plus a delivery fee based on your order value: ₹25 for orders up to ₹499, ₹15 for orders between ₹500 and ₹999, and FREE delivery for all orders above ₹1000 (and above ₹149 for our Drishti Platinum Members).',
      ),
      FaqItem(
        question: 'How long does delivery take?',
        answer:
            'Domestic orders are typically delivered within 5-7 days. International orders typically within 10-15 days. Timelines are estimates and may occasionally vary due to unforeseen logistics delays.',
      ),
    ]),
    FaqCategory(heading: '3. Payments & Discounts', items: [
      FaqItem(
        question: 'What payment methods do you accept?',
        answer:
            'We accept Credit Cards, Debit Cards, Net Banking, UPI apps (Google Pay, PhonePe, Paytm, etc.), digital wallets, e-Gift cards, and Cash on Delivery (COD) through our secure payment gateways.',
      ),
      FaqItem(
        question: 'How do I apply a discount or promo code?',
        answer:
            'During checkout you will see an "Apply Promo Code" or "Discount Coupon" box. Enter your code there and tap apply to see the discounted total before making your payment.',
      ),
      FaqItem(
        question: 'Is it safe to use my credit/debit card on the platform?',
        answer:
            'Yes, absolutely. All online transactions are processed through encrypted, secure payment gateways (such as Cashfree). Fashions Drishti never stores your complete card details or CVV.',
      ),
    ]),
    FaqCategory(heading: '4. Returns, Exchanges & Refunds', items: [
      FaqItem(
        question: 'What is your return policy?',
        answer:
            'Most domestic items are eligible for return or replacement within 5 days of delivery, provided they are unused, unwashed, and have all original tags intact. Made-to-order items and international orders are not eligible for returns.',
      ),
      FaqItem(
        question: 'My garment does not fit. Can I exchange it?',
        answer:
            'Yes! If the size does not fit, you can request a size exchange through the "My Orders" section within 5 days of receiving the item. If your requested size is out of stock, we will offer a standard return option.',
      ),
      FaqItem(
        question: 'When will I receive my refund?',
        answer:
            'For cancellations, refunds are processed within 3 business days. For returns, refunds are initiated once our courier partner picks up the item. Expenses are refunded to your original payment source, while COD refunds go to your provided bank account or UPI ID.',
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text('FAQ', style: AppTextStyles.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Welcome to the Drishti Fashions Help Desk! We have put together answers to the most common questions our shoppers ask.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.6, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.lg),
            for (final category in _categories) ...[
              Text(category.heading, style: AppTextStyles.subtitle),
              const SizedBox(height: AppDimensions.sm),
              for (final item in category.items) _FaqTile(item: item),
              const SizedBox(height: AppDimensions.lg),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Still Need Help?', style: AppTextStyles.subtitle),
                  const SizedBox(height: AppDimensions.sm),
                  _contactLine('Mr. Prakash — Operations Head', Iconsax.user),
                  _contactLine('+91 6290486090 (Mon-Sat, 10 AM to 7 PM)', Iconsax.call),
                  _contactLine('info@drishtifashions.com', Iconsax.sms),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xxl),
          ],
        ),
      ),
    );
  }

  Widget _contactLine(String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.brandGoldDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.6, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});
  final FaqItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: AppColors.brandGoldDark,
        collapsedIconColor: AppColors.brandGoldDark,
        title: Text(
          item.question,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.answer,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.6, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}