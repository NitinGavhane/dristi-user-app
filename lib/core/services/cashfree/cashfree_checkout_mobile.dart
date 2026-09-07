import 'dart:developer';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';

import 'cashfree_models.dart';

/// Mobile (Android/iOS) Cashfree checkout using the flutter_cashfree_pg_sdk
/// plugin. The plugin opens Cashfree's hosted checkout in a web view and
/// reports back the merchant order id on completion.
class CashfreeCheckout {
  CashfreeSuccessCallback? _onSuccess;
  CashfreeErrorCallback? _onError;

  void open(
    CashfreeOptions options, {
    required CashfreeSuccessCallback onSuccess,
    required CashfreeErrorCallback onError,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;

    final environment = options.cashfreeEnvironment.toLowerCase() == 'production'
        ? CFEnvironment.PRODUCTION
        : CFEnvironment.SANDBOX;

    final session = CFSessionBuilder()
        .setEnvironment(environment)
        .setOrderId(options.cashfreeOrderId)
        .setPaymentSessionId(options.paymentSessionId)
        .build();

    final payment = CFWebCheckoutPaymentBuilder().setSession(session).build();

    log('Cashfree: opening checkout for order ${options.cashfreeOrderId} '
        '(env=${options.cashfreeEnvironment})');

    CFPaymentGatewayService().setCallback(
      (orderId) {
        log('Cashfree: payment success for order $orderId');
        _onSuccess?.call(CashfreeSuccess(cashfreeOrderId: orderId));
      },
      (CFErrorResponse error, String orderId) {
        final code = error.getCode();
        final message = error.getMessage();
        log('Cashfree: payment error for order $orderId — '
            'code=$code message=$message');
        _onError?.call(message ?? 'Payment failed. Please try again.');
      },
    );
    CFPaymentGatewayService().doPayment(payment);
  }

  void dispose() {
    CFPaymentGatewayService().setCallback(
      (String orderId) {},
      (CFErrorResponse error, String orderId) {},
    );
    _onSuccess = null;
    _onError = null;
  }
}