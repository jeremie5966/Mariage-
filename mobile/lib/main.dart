import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final token = preferences.getString('auth_token');
  final role = preferences.getString('auth_role') ?? 'staff';
  runApp(MariageApp(initialToken: token, initialRole: role));
}
