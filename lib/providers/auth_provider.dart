import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  Session? _session;
  String? _error;
  bool _isLoading = false;

  Session? get session => _session;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _session != null;

  Future<void> initialize() async {
    await _supabaseService.initialize();
    final client = _supabaseService.client;
    _session = client?.auth.currentSession;
    client?.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final client = _supabaseService.client;
      if (client == null) {
        throw const AuthException('Supabase not configured');
      }
      final res = await client.auth.signInWithPassword(email: email, password: password);
      _session = res.session;
      return _session != null;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final client = _supabaseService.client;
      if (client == null) {
        throw const AuthException('Supabase not configured');
      }
      final res = await client.auth.signUp(email: email, password: password);
      _session = res.session;
      return true; // Supabase may require email confirm; treat as success
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      final client = _supabaseService.client;
      await client?.auth.signOut();
      _session = null;
    } catch (_) {}
    notifyListeners();
  }
}

