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
    final url = Uri.parse('https://msapi.top-academy.ru/api/v2/auth/login');
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

        final getUrl = Uri.parse(
          'https://msapi.top-academy.ru/api/v2/settings/user-info',
        );
        final getHeaders = {...headers, 'Authorization': 'Bearer $authToken'};
        final getResponse = await http.get(getUrl, headers: getHeaders);
        // ignore: avoid_print
        print('GET Response Status: ${getResponse.statusCode}');
        // ignore: avoid_print
        print('GET Response Body: ${getResponse.body}');

        if (getResponse.statusCode == 200) {
          final userInfo = jsonDecode(getResponse.body);

          final homeworkUrl = Uri.parse(
            'https://msapi.top-academy.ru/api/v2/count/homework',
          );
          final homeworkResponse = await http.get(
            homeworkUrl,
            headers: getHeaders,
          );
          // ignore: avoid_print
          print('Homework Response Status: ${homeworkResponse.statusCode}');
          // ignore: avoid_print
          print('Homework Response Body: ${homeworkResponse.body}');

          if (homeworkResponse.statusCode == 200) {
            final homeworkData = jsonDecode(homeworkResponse.body);

            // Get average progress data
            final progressUrl = Uri.parse(
              'https://msapi.top-academy.ru/api/v2/dashboard/chart/average-progress',
            );
            final progressResponse = await http.get(
              progressUrl,
              headers: getHeaders,
            );
            // ignore: avoid_print
            print('Progress Response Status: ${progressResponse.statusCode}');
            // ignore: avoid_print
            print('Progress Response Body: ${progressResponse.body}');

            // Get attendance data
            final attendanceUrl = Uri.parse(
              'https://msapi.top-academy.ru/api/v2/dashboard/chart/attendance',
            );
            final attendanceResponse = await http.get(
              attendanceUrl,
              headers: getHeaders,
            );
            // ignore: avoid_print
            print(
              'Attendance Response Status: ${attendanceResponse.statusCode}',
            );
            // ignore: avoid_print
            print('Attendance Response Body: ${attendanceResponse.body}');

            // Add after the attendance request and before the navigation

            // Get group leaderboard data
            final groupLeaderUrl = Uri.parse(
              'https://msapi.top-academy.ru/api/v2/dashboard/progress/leader-group-points',
            );
            final groupLeaderResponse = await http.get(
              groupLeaderUrl,
              headers: getHeaders,
            );
            // ignore: avoid_print
            print(
              'Group Leader Response Status: ${groupLeaderResponse.statusCode}',
            );
            // ignore: avoid_print
            print('Group Leader Response Body: ${groupLeaderResponse.body}');

            // Get stream leaderboard data
            final streamLeaderUrl = Uri.parse(
              'https://msapi.top-academy.ru/api/v2/dashboard/progress/leader-stream-points',
            );
            final streamLeaderResponse = await http.get(
              streamLeaderUrl,
              headers: getHeaders,
            );
            // ignore: avoid_print
            print(
              'Stream Leader Response Status: ${streamLeaderResponse.statusCode}',
            );
            // ignore: avoid_print
            print('Stream Leader Response Body: ${streamLeaderResponse.body}');

            // Add after the stream leader request and before the navigation check

            // Get leader stream data
            final leaderStreamUrl = Uri.parse(
              'https://msapi.top-academy.ru/api/v2/dashboard/progress/leader-stream',
            );
            final leaderStreamResponse = await http.get(
              leaderStreamUrl,
              headers: getHeaders,
            );
            // ignore: avoid_print
            print(
              'Leader Stream Response Status: ${leaderStreamResponse.statusCode}',
            );
            // ignore: avoid_print
            print('Leader Stream Response Body: ${leaderStreamResponse.body}');

            // Get leader group data
            final leaderGroupUrl = Uri.parse(
              'https://msapi.top-academy.ru/api/v2/dashboard/progress/leader-group',
            );
            final leaderGroupResponse = await http.get(
              leaderGroupUrl,
              headers: getHeaders,
            );
            // ignore: avoid_print
            print(
              'Leader Group Response Status: ${leaderGroupResponse.statusCode}',
            );
            // ignore: avoid_print
            print('Leader Group Response Body: ${leaderGroupResponse.body}');

            // Update the success condition check and data passing
            if (progressResponse.statusCode == 200 &&
                attendanceResponse.statusCode == 200 &&
                groupLeaderResponse.statusCode == 200 &&
                streamLeaderResponse.statusCode == 200 &&
                leaderStreamResponse.statusCode == 200 &&
                leaderGroupResponse.statusCode == 200) {
              final progressData = jsonDecode(progressResponse.body);
              final attendanceData = jsonDecode(attendanceResponse.body);
              final groupLeaderData = jsonDecode(groupLeaderResponse.body);
              final streamLeaderData = jsonDecode(streamLeaderResponse.body);
              final leaderStreamData = jsonDecode(leaderStreamResponse.body);
              final leaderGroupData = jsonDecode(leaderGroupResponse.body);

              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ProfilePage(
                        userInfo: userInfo,
                        homeworkData: homeworkData,
                        progressData: progressData,
                        attendanceData: attendanceData,
                        groupLeaderData: groupLeaderData,
                        streamLeaderData: streamLeaderData,
                        leaderStreamData: leaderStreamData,
                        leaderGroupData: leaderGroupData,
                      ),
                ),
              );
            } else {
              setState(() {
                _errorMessage = 'Failed to fetch all required data';
              });
            }
          } else {
            setState(() {
              _errorMessage = 'Failed to fetch homework data';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to fetch user info';
          });
        }
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: Checkbox(
                      value: _rememberPassword,
                      onChanged: _toggleRememberPassword,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleRememberPassword(!_rememberPassword),
                    child: Text('Запомнить пароль', textAlign: TextAlign.left),
                  ),
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
      ),
    );
  }
}
