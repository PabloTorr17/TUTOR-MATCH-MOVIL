// lib/features/payment/data/payment_repository.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/api/api_client.dart';

class PaymentRepository {
  final ApiClient _api = ApiClient();

  /// Crea un PaymentIntent en el backend y devuelve el clientSecret
  Future<String> createPaymentIntent({
    required String sessionId,
    required double amount,
    String currency = 'mxn',
  }) async {
    final response = await _api.post('/payments/create-intent', data: {
      'session_id': sessionId,
      'amount': amount,
      'currency': currency,
    });
    return response.data['data']['client_secret'];
  }

  /// Confirma el pago con Stripe y registra la inscripcion en el backend
  Future<void> processPaymentAndEnroll({
    required String sessionId,
    required String clientSecret,
  }) async {
    // Inicializar la hoja de pago de Stripe
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'TutorMatch',
        style: ThemeMode.light,
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: Color(0xFF0D0D0D),
            background: Color(0xFFFFFFFF),
          ),
          shapes: PaymentSheetShape(
            borderRadius: 8,
            borderWidth: 1.5,
          ),
        ),
      ),
    );

    // Presentar la hoja de pago al usuario
    await Stripe.instance.presentPaymentSheet();

    // Si llega aqui, el pago fue exitoso — inscribir al usuario
    await _api.post('/sessions/$sessionId/enroll');
  }

  /// Para asesorias gratis, inscribe directamente sin Stripe
  Future<void> enrollFree(String sessionId) async {
    await _api.post('/sessions/$sessionId/enroll');
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => PaymentRepository());
