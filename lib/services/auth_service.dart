import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  bool _isAdmin = true;

  bool get isAdmin => _isAdmin;

  Future<bool> isAdminUser() async {
    return _isAdmin;
  }
}