// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String baseUrl = 'https://tutor-match-backend.vercel.app/api/v1';

  // Stripe — reemplaza con tu publishable key de Stripe Dashboard
  static const String stripePublishableKey = 'pk_test_51Td1fo1Atb0bhefly5xtkWDDBcb8vDBkxdtBxDmeq9bUDDkBmQukQBbC92GzDSNhWymgvz9M5S9JWaxSfb0sPia200JlJwGVxk';

  // Supabase — reemplaza con los valores de tu proyecto
  static const String supabaseUrl = 'https://nuaqjgrbzxwcrwlloehq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51YXFqZ3Jienh3Y3J3bGxvZWhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4NTAzMzMsImV4cCI6MjA5NTQyNjMzM30.BgJ8EWQm4cy04uQaWC8UvbZJV1hVKyd08ayBMvIR_IM';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Paginacion
  static const int pageSize = 10;

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
