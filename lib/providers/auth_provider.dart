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

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> checkAuth() async {
    await ApiClient.init();

    // Restore the cached session first so a shopper who closed the app while
    // signed in is never shown the login screen while the network decides the
    // token's fate below. A poor connection must not log anyone out.
    _user = await _loadCachedUser();

    if (!await ApiClient.hasToken()) {
      notifyListeners();
      return;
    }

    try {
      final profile = await AuthApiService.getProfile();
      _user = User.fromJson(profile);
      await _cacheUser(_user!);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // The access token is rejected — it may simply be expired. Try once to
        // refresh it, keeping the cached session alive either way.
        try {
          await AuthApiService.refreshToken();
          final profile = await AuthApiService.getProfile();
          _user = User.fromJson(profile);
          await _cacheUser(_user!);
        } on ApiException catch (refreshError) {
          if (refreshError.statusCode == 401) {
            // The server explicitly rejected the refresh token, so this session
            // genuinely can no longer be restored. Only then do we sign out.
            _user = null;
            await _clearCachedUser();
            await AuthApiService.logout();
          }
          // Any other refresh failure (offline, timeout, 5xx) is transient —
          // keep the cached session and tokens so the next launch retries.
        } catch (_) {
          // Non-API exception during refresh — keep the cached session.
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
