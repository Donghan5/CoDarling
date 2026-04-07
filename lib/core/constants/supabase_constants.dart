class SupabaseConstants {
  SupabaseConstants._();

  // Set these via --dart-define or environment injection
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
}
