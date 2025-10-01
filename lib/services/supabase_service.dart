import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!SupabaseConfig.isConfigured) {
      _initialized = true; // allow app to run offline without cloud
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _initialized = true;
  }

  SupabaseClient? get client => SupabaseConfig.isConfigured ? Supabase.instance.client : null;
}

