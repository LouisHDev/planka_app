import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class AuthProvider with ChangeNotifier {
  String _token = '';
  String _domain = '';

  String get token => _token;
  String get domain => _domain;

  Future<void> login(String emailOrUsername, String password, String domain, BuildContext context) async {
    _domain = domain;
    final url = Uri.parse('https://$domain/api/access-tokens');

    try {
      final response = await http.post(
        url,
        body: json.encode({'emailOrUsername': emailOrUsername, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _token = responseData['item'];

        await _saveCredentials(); // Save credentials after successful login

        notifyListeners();
      } else {
        debugPrint('Failed to authenticate: ${response.body}');
        throw Exception('Something is wrong with your token.');
      }
    } catch (error) {
      debugPrint('Error: $error');
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message:
          "failed_to_authenticate".tr(),
        ),
      );
      throw Exception('failed_to_authenticate'.tr());
    }
  }

  Future<bool> logout(BuildContext context) async {
    final url = Uri.parse('https://$_domain/api/access-tokens/me');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        _token = '';
        _domain = '';
        await _clearCredentials(); // Clear credentials on logout
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (error) {
      debugPrint('Error: $error');
      throw Exception('Failed to logout');
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token);
    await prefs.setString('domain', _domain);
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('domain');
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token') || !prefs.containsKey('domain')) {
      return;
    }

    _token = prefs.getString('token')!;
    _domain = prefs.getString('domain')!;
    notifyListeners();
  }
}