import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';
import 'package:journal_it_top/services/api_service.dart';
import 'package:journal_it_top/models/homework_item.dart';
import 'package:journal_it_top/models/lesson_visit_mark.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _rememberPassword = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // ignore: avoid_print
    print('AppLifecycleState changed to: $state for LoginPage');
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        // ignore: avoid_print
        print('LoginPage resumed, forcing UI refresh if needed.');
        setState(() {});
      }
    }
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

    if (mounted) {
      // Проверка mounted перед setState
      setState(() {
        _rememberPassword = rememberPassword;
        if (savedUsername != null) {
          _usernameController.text = savedUsername;
        }
        if (rememberPassword && savedPassword != null) {
          _passwordController.text = savedPassword;
        }
      });
    }
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
    if (_isLoading) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final url = Uri.parse('https://msapi.top-academy.ru/api/v2/auth/login');
    final baseHeadersForLogin = {
      'Content-Type': 'application/json',
      'authority': 'msapi.top-academy.ru',
      'origin': 'https://journal.top-academy.ru',
      'referer': 'https://journal.top-academy.ru/',
    };

    final payload = {
      'application_key':
          '6a56a5df2667e65aab73ce76d1dd737f7d1faef9c52e8b8c55ac75f565d8e8a6',
      'password': _passwordController.text.trim(),
      'username': _usernameController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: baseHeadersForLogin,
        body: jsonEncode(payload),
      );

      if (!mounted) return; // Проверка после await

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String? authToken = responseBody['access_token'];

        if (authToken != null) {
          await _saveCredentials();

          final apiService = ApiService(authToken: authToken);
          final dataHeadersWithToken = apiService.headers;

          // ignore: avoid_print
          print("Starting to fetch all homework in background...");
          final Future<List<HomeworkItem>> allHomeworkFuture =
              apiService.fetchAllHomework().catchError((error) {
            // ignore: avoid_print
            print("Error fetching all homework in background: $error");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ошибка фоновой загрузки ДЗ.')),
              );
            }
            return <HomeworkItem>[];
          });

          // ignore: avoid_print
          print("Starting to fetch all lesson visits/marks in background...");
          final Future<List<LessonVisitMark>> allLessonVisitsFuture =
              apiService.fetchLessonVisitsAndMarks().catchError((error) {
            // ignore: avoid_print
            print("Error fetching lesson visits/marks in background: $error");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Ошибка фоновой загрузки оценок.')),
              );
            }
            return <LessonVisitMark>[];
          });

          final results = await Future.wait([
            http.get(
                Uri.parse(
                    'https://msapi.top-academy.ru/api/v2/settings/user-info'),
                headers: dataHeadersWithToken),
            http.get(
                Uri.parse('https://msapi.top-academy.ru/api/v2/count/homework'),
                headers: dataHeadersWithToken),
            http.get(
                Uri.parse(
                    'https://msapi.top-academy.ru/api/v2/dashboard/chart/average-progress'),
                headers: dataHeadersWithToken),
            http.get(
                Uri.parse(
                    'https://msapi.top-academy.ru/api/v2/dashboard/chart/attendance'),
                headers: dataHeadersWithToken),
            http.get(
                Uri.parse(
                    'https://msapi.top-academy.ru/api/v2/dashboard/progress/leader-group-points'),
                headers: dataHeadersWithToken),
            http.get(
                Uri.parse(
                    'https://msapi.top-academy.ru/api/v2/dashboard/progress/leader-stream-points'),
                headers: dataHeadersWithToken),
            http.get(
                Uri.parse(
                    'https://msapi.top-academy.ru/api/v2/dashboard/progress/leader-stream'),
                headers: dataHeadersWithToken),
            http.get(
                Uri.parse(
                    'https://msapi.top-academy.ru/api/v2/dashboard/progress/leader-group'),
                headers: dataHeadersWithToken),
          ]);

          if (!mounted) return; // Проверка после await

          bool allRequestsSuccessful = true;
          for (var res in results) {
            if (res.statusCode != 200) {
              allRequestsSuccessful = false;
              // ignore: avoid_print
              print(
                  'Error in data request: ${res.request?.url} - ${res.statusCode} - ${res.body}');
              setState(() {
                // mounted уже проверен
                _errorMessage =
                    'Ошибка загрузки данных профиля (код: ${res.statusCode})';
              });
              break;
            }
          }

          if (allRequestsSuccessful) {
            final userInfo = jsonDecode(results[0].body);
            final homeworkRaw = jsonDecode(results[1].body);
            final progressRaw = jsonDecode(results[2].body);
            final attendanceRaw = jsonDecode(results[3].body);
            final groupLeaderData = jsonDecode(results[4].body);
            final streamLeaderData = jsonDecode(results[5].body);
            final leaderStreamRaw = jsonDecode(results[6].body);
            final leaderGroupRaw = jsonDecode(results[7].body);

            List<dynamic> parseList(dynamic rawData) {
              if (rawData is List) return rawData;
              if (rawData is Map<String, dynamic> &&
                  rawData.containsKey('data') &&
                  rawData['data'] is List) {
                return List<dynamic>.from(rawData['data']);
              }
              return [];
            }

            // mounted уже проверен
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  authToken: authToken,
                  userInfo: userInfo,
                  homeworkData: parseList(homeworkRaw),
                  progressData: parseList(progressRaw),
                  attendanceData: parseList(attendanceRaw),
                  groupLeaderData: groupLeaderData,
                  streamLeaderData: streamLeaderData,
                  leaderStreamData: parseList(leaderStreamRaw),
                  leaderGroupData: parseList(leaderGroupRaw),
                  allHomeworkFuture: allHomeworkFuture,
                  allLessonVisitsFuture: allLessonVisitsFuture,
                ),
              ),
            );
          } else if (_errorMessage == null) {
            // Если ошибка была, но _errorMessage не установлен
            setState(() {
              // mounted уже проверен
              _errorMessage = 'Не удалось загрузить все данные пользователя.';
            });
          }
        } else {
          setState(() {
            // mounted уже проверен
            _errorMessage = 'Токен авторизации не получен.';
          });
        }
      } else if (response.statusCode == 422) {
        setState(() {
          // mounted уже проверен
          _errorMessage = 'Неверный логин или пароль.';
        });
      } else {
        // ignore: avoid_print
        print('Login error: ${response.statusCode} - ${response.body}');
        setState(() {
          // mounted уже проверен
          _errorMessage =
              'Ошибка входа (код: ${response.statusCode}). Попробуйте позже.';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Network or general error during login: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Произошла ошибка. Проверьте интернет-соединение.';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход в дневник'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Логин',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0))),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _rememberPassword,
                    onChanged: _isLoading ? null : _toggleRememberPassword,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => _toggleRememberPassword(!_rememberPassword),
                    child: const Text('Запомнить пароль'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Войти', style: TextStyle(fontSize: 16)),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
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
