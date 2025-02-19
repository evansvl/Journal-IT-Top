import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();

  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _rememberPassword = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _toggleRememberPassword(bool? value) async {
    setState(() {
      _rememberPassword = value ?? false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_password', _rememberPassword);
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final savedPassword = prefs.getString('saved_password');
    final rememberPassword = prefs.getBool('remember_password') ?? false;
    setState(() {
      _rememberPassword = rememberPassword;
      if (savedUsername != null) _usernameController.text = savedUsername;
      if (rememberPassword && savedPassword != null) {
        _passwordController.text = savedPassword;
      }
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_username', _usernameController.text);
    if (_rememberPassword) {
      await prefs.setString('saved_password', _passwordController.text);
    } else {
      await prefs.remove('saved_password');
    }
  }

  Future<void> _login() async {
    final url = Uri.parse('https://proxy.evansvl.ru:8444/api/v2/auth/login');
    final headers = {
      'Content-Type': 'application/json',
      'authority': 'msapi.top-academy.ru',
      'origin': 'https://journal.top-academy.ru',
      'referer': 'https://journal.top-academy.ru/',
    };

    final payload = {
      'application_key':
          '6a56a5df2667e65aab73ce76d1dd737f7d1faef9c52e8b8c55ac75f565d8e8a6',
      'password': _passwordController.text,
      'username': _usernameController.text,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final authToken = responseBody['access_token'];
      if (authToken != null) {
        await _saveCredentials();
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Auth token not found';
        });
      }
    } else if (response.statusCode == 422) {
      setState(() {
        _errorMessage = 'Неверный логин или пароль';
      });
    } else {
      setState(() {
        _errorMessage = 'Failed request with status: ${response.statusCode}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Journal'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Логин'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'Пароль',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _rememberPassword,
                  onChanged: _toggleRememberPassword,
                ),
                Text('Remember Password'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('Вход')),
            if (_errorMessage != null) ...[
              SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
