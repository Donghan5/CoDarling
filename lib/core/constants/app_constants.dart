class AppConstants {
  AppConstants._();

  static const String appName = 'Codarling';
  static const String photosBucket = 'photos';
  static const int inviteCodeLength = 11; // e.g. "LOVE-7X2K9M"

  // Supabase project — used for OAuth deep-link scheme
  static const String supabaseProjectRef = 'ecdshhuvypmgxalpriab';
  static const String oauthRedirectUri =
      'io.supabase.$supabaseProjectRef://login-callback/';

  // Validation limits
  static const int maxCaptionLength = 300;
  static const int maxDisplayNameLength = 100;
  static const int maxPhotoSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const Set<String> allowedPhotoExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'heic',
  };

  // Invite code expiry
  static const Duration inviteCodeExpiry = Duration(days: 7);

  // Table names
  static const String usersTable = 'users';
  static const String couplesTable = 'couples';
  static const String photosTable = 'photos';
  static const String promptsTable = 'prompts';
  static const String promptRepliesTable = 'prompt_replies';
  static const String reactionsTable = 'reactions';
  static const String fcmTokensTable = 'fcm_tokens';
}
