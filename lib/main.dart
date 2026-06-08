// lib/main.dart — ACTUALIZADO
// Agrega Firebase, notificaciones push y quita bloqueo de orientacion

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/api/api_client.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/push_notifications_service.dart';

// Handler de background para Firebase (debe ser top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensaje en background: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // LANDSCAPE: permitir todas las orientaciones
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await initializeDateFormatting('es');

  // Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Stripe en background
  Stripe.publishableKey = AppConstants.stripePublishableKey;
  unawaited(Stripe.instance.applySettings());

  // API client
  ApiClient().init();

  runApp(const ProviderScope(child: TutorMatchApp()));
}

class TutorMatchApp extends ConsumerStatefulWidget {
  const TutorMatchApp({super.key});

  @override
  ConsumerState<TutorMatchApp> createState() => _TutorMatchAppState();
}

class _TutorMatchAppState extends ConsumerState<TutorMatchApp> {
  @override
  void initState() {
    super.initState();
    // Inicializar notificaciones push despues de que el widget este montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationsService().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'TutorMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
