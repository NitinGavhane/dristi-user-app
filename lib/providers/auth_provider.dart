import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/api_client.dart';
import '../core/services/auth_api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  final Completer<void> _initializedCompleter = Completer<void>();

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  /// True once the cached session (or its absence) is known and the app can
  /// decide how to present the UI. Cold start must wait for this before
  /// navigating, so a slow token refresh can never show a fake logged-out
  /// screen or push the login page over a live session.
  Future<void> get initialized => _initializedCompleter.future;

  Future<void> checkAuth() async {
    await ApiClient.init();

    // Restore the cached session first so a shopper who closed the app while
    // signed in is never shown the login screen while the network decides the
    // token's fate below. A poor connection must not log anyone out.
    _user = await _loadCachedUser();

    // The session's presence is now decided — unblock the splash so the app
    // can open in the correct state while the token refresh below runs in the
    // background and silently updates the session.
    if (!_initializedCompleter.isCompleted) {
      _initializedCompleter.complete();
      notifyListeners();
    }

    if (!await ApiClient.hasToken()) {
      notifyListeners();
      return;
    }

    // Background session refresh — best-effort. The cached user is kept in all
    // cases so the app never force-logs the user out on restart. A stale
    // session will simply fail on the next authenticated request, at which
    // point the user can re-login. Only the explicit logout() method should
    // clear the session.
    try {
      final profile = await AuthApiService.getProfile();
      _user = User.fromJson(profile);
      await _cacheUser(_user!);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Access token expired — try a single refresh attempt. If the refresh
        // token itself is rejected we still keep the cached session: the user
        // stays logged in with stale data and can re-login when an action
        // actually requires a valid token.
        try {
          await AuthApiService.refreshToken();
          final profile = await AuthApiService.getProfile();
          _user = User.fromJson(profile);
          await _cacheUser(_user!);
        } catch (_) {
          // Refresh failed (401 or network) — keep the cached session intact.
          // The user will appear logged in until they hit an action that
          // needs a fresh token, which will surface a proper re-login prompt.
        }
      }
      // Non-401 failures (network, 5xx) also keep the cached session.
    } catch (_) {
      // Any other failure — keep the cached session.
    }
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthApiService.login(email: email, password: password);
      final profile = await AuthApiService.getProfile();
      _user = User.fromJson(profile);
      await _cacheUser(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendLoginOtp({
    required String email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthApiService.sendLoginOtp(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithOtp({
    required String email,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthApiService.loginWithOtp(email: email, otp: otp);
      _user = User.fromJson(result['user']);
      await _cacheUser(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthApiService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        referralCode: referralCode,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthApiService.verifyOtp(email: email, otp: otp);
      if (result.containsKey('user') && result['user'] != null) {
        _user = User.fromJson(result['user'] as Map<String, dynamic>);
      } else if (await ApiClient.hasToken()) {
        final profile = await AuthApiService.getProfile();
        _user = User.fromJson(profile);
      }
      if (_user != null) {
        await _cacheUser(_user!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp({
    required String email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthApiService.resendOtp(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword({
    required String email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthApiService.forgotPassword(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthApiService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthApiService.updateProfile(
        fullName: fullName,
        email: email,
        phone: phone,
      );
      _user = User.fromJson(result);
      await _cacheUser(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Called by other providers/services when an authenticated API call returns
  /// 401 *after* the background refresh has already tried and failed. This is
  /// the only path (besides explicit logout) that should clear the session.
  Future<void> handleAuthFailure() async {
    if (_user == null) return;
    _user = null;
    await _clearCachedUser();
    await AuthApiService.logout();
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthApiService.logout();
    await _clearCachedUser();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _cacheUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(user.toJson()));
  }

  Future<User?> _loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('cached_user');
      if (data != null) {
        return User.fromJson(jsonDecode(data) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _clearCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }
}
