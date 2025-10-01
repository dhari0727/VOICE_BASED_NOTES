class SupabaseConfig {
  // Hardcoded Supabase project values (for development/testing only)
  static const String supabaseUrl = 'https://hdshgmnpwimlojnyoboz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhkc2hnbW5wd2ltbG9qbnlvYm96Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyOTY3ODAsImV4cCI6MjA3NDg3Mjc4MH0.5N4INAlWIkh9qnBX7WzSCZfmYiwcw7lK6FZflF5pSLg';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
