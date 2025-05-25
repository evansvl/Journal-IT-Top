import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:journal_it_top/schedule.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'package:journal_it_top/models/homework_item.dart';
import 'package:journal_it_top/models/lesson_visit_mark.dart';

class ProfilePage extends StatefulWidget {
  final String authToken;
  final Map<String, dynamic> userInfo;
  final List<dynamic> homeworkData;
  final List<dynamic> progressData;
  final List<dynamic> attendanceData;
  final Map<String, dynamic> groupLeaderData;
  final Map<String, dynamic> streamLeaderData;
  final List<dynamic> leaderStreamData;
  final List<dynamic> leaderGroupData;
  final Future<List<HomeworkItem>> allHomeworkFuture;
  final Future<List<LessonVisitMark>> allLessonVisitsFuture;

  const ProfilePage({
    super.key,
    required this.authToken,
    required this.userInfo,
    required this.homeworkData,
    required this.progressData,
    required this.attendanceData,
    required this.groupLeaderData,
    required this.streamLeaderData,
    required this.leaderStreamData,
    required this.leaderGroupData,
    required this.allHomeworkFuture,
    required this.allLessonVisitsFuture,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isGroupTab = true;

  late int _coins, _gems, _totalPoints;
  late int _currentHW, _onCheckHW, _checkedHW, _expiredHW, _allHWCounters;
  late int _avgGradeValue, _attendanceValue;
  late int _groupTopPosition, _streamTopPosition;
  late List<Map<String, dynamic>> _groupLeaders;
  late List<Map<String, dynamic>> _streamLeadersFiltered;

  late String _userName;
  late String _userAvatarLetter;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _parseUserInfo();
    _parseProfileData();
  }

  void _parseUserInfo() {
    _userName = widget.userInfo['full_name'] as String? ?? 'Профиль';
    _userAvatarLetter = _userName.isNotEmpty ? _userName[0].toUpperCase() : "П";
    _userPhotoUrl = widget.userInfo['photo'] as String?;

    if (_userPhotoUrl != null && _userPhotoUrl!.isEmpty) {
      _userPhotoUrl = null;
    }
  }

  void _parseProfileData() {
    var gamingPointsList =
        widget.userInfo['gaming_points'] as List<dynamic>? ?? [];
    _coins = 0;
    _gems = 0;
    for (var pointData in gamingPointsList) {
      if (pointData is Map<String, dynamic>) {
        int typeId = pointData['new_gaming_point_types__id'] as int? ?? 0;
        int points = pointData['points'] as int? ?? 0;
        if (typeId == 1) {
          _coins = points;
        } else if (typeId == 2) {
          _gems = points;
        }
      }
    }
    _totalPoints = _coins + _gems;

    int getHWCcounter(List<dynamic> hwList, int index, String keyName) {
      if (hwList.length > index && hwList[index] is Map<String, dynamic>) {
        return (hwList[index] as Map<String, dynamic>)[keyName] as int? ?? 0;
      }
      return 0;
    }

    _checkedHW = getHWCcounter(widget.homeworkData, 0, 'counter');
    _currentHW = getHWCcounter(widget.homeworkData, 1, 'counter');
    _expiredHW = getHWCcounter(widget.homeworkData, 2, 'counter');
    _onCheckHW = getHWCcounter(widget.homeworkData, 3, 'counter');
    int returnedHW = getHWCcounter(widget.homeworkData, 4, 'counter');
    _allHWCounters =
        _checkedHW + _currentHW + _expiredHW + _onCheckHW + returnedHW;

    _avgGradeValue =
        widget.progressData.isNotEmpty && widget.progressData.last is Map
            ? (widget.progressData.last['points'] as int? ?? 0)
            : 0;
    _attendanceValue =
        widget.attendanceData.isNotEmpty && widget.attendanceData.last is Map
            ? (widget.attendanceData.last['points'] as int? ?? 0)
            : 0;

    _groupTopPosition =
        (widget.groupLeaderData['studentPosition'] as int?) ?? 0;
    _streamTopPosition =
        (widget.streamLeaderData['studentPosition'] as int?) ?? 0;

    _groupLeaders =
        (widget.leaderGroupData).map<Map<String, dynamic>>((leader) {
      return {
        'name': leader['full_name']?.toString() ?? 'N/A',
        'amount': (leader['amount'] as int?) ?? 0,
        'position': (leader['position'] as int?) ?? 0,
      };
    }).toList();

    _streamLeadersFiltered = (widget.leaderStreamData)
        .where((leader) =>
            leader['id'] != null ||
            leader['full_name'] != null ||
            leader['amount'] != null)
        .map<Map<String, dynamic>>((leader) {
      return {
        'name': leader['full_name']?.toString() ?? 'N/A',
        'amount': (leader['amount'] as int?) ?? 0,
        'position': (leader['position'] as int?) ?? 0,
      };
    }).toList();
  }

  void _switchTab(bool isGroup) {
    setState(() {
      _isGroupTab = isGroup;
    });
  }

  Future<List<dynamic>> _fetchScheduleForDate(String date) async {
    try {
      final scheduleUrl = Uri.parse(
        'https://msapi.top-academy.ru/api/v2/schedule/operations/get-by-date?date_filter=$date',
      );
      // ignore: avoid_print
      print(
          'Fetching schedule (ProfilePage) for $date with token: ${widget.authToken.substring(0, 10)}...');

      final response = await http.get(
        scheduleUrl,
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
          'authority': 'msapi.top-academy.ru',
          'origin': 'https://journal.top-academy.ru',
          'referer': 'https://journal.top-academy.ru/',
        },
      );

      // ignore: avoid_print
      print('Schedule Response (ProfilePage): ${response.statusCode}');
      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('Schedule Response Body (ProfilePage): ${response.body}');
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('data')) {
          return List<dynamic>.from(jsonResponse['data'] ?? []);
        } else if (jsonResponse is List) {
          return List<dynamic>.from(jsonResponse);
        }
        return [];
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching schedule in ProfilePage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки расписания: $e')),
        );
      }
      return [];
    }
  }

  Widget _buildDrawerPointsItem(String assetPath, int points,
      {bool isTotal = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(assetPath,
            width: isTotal ? 18 : 16, height: isTotal ? 18 : 16),
        const SizedBox(width: 4),
        Text(
          '$points',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_userName),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withAlpha((255 * 0.8).round()),
                        backgroundImage:
                            _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                                ? NetworkImage(_userPhotoUrl!)
                                : null,
                        child: (_userPhotoUrl == null || _userPhotoUrl!.isEmpty)
                            ? Text(
                                _userAvatarLetter,
                                style: const TextStyle(
                                    fontSize: 30.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        _buildDrawerPointsItem(
                            'assets/images/top-money.png', _totalPoints,
                            isTotal: true),
                        const SizedBox(width: 16),
                        _buildDrawerPointsItem(
                            'assets/images/top-coin.png', _coins),
                        const SizedBox(width: 16),
                        _buildDrawerPointsItem(
                            'assets/images/top-gem.png', _gems),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Расписание'),
              onTap: () async {
                if (!mounted) return;
                final BuildContext localContext = context;

                Navigator.pop(localContext);

                final String today =
                    DateFormat('yyyy-MM-dd').format(DateTime.now());

                if (!mounted) return;
                showDialog(
                  context: localContext,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                final scheduleData = await _fetchScheduleForDate(today);

                if (!mounted) return;
                Navigator.pop(localContext);

                if (!mounted) return;
                Navigator.push(
                  localContext,
                  MaterialPageRoute<void>(
                    builder: (BuildContext pageRouteContext) => SchedulePage(
                      initialSchedule: scheduleData,
                      authToken: widget.authToken,
                      allHomeworkFuture: widget.allHomeworkFuture,
                      allLessonVisitsFuture: widget.allLessonVisitsFuture,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1, thickness: 0.5),
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('Выход'),
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                }
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Выход из аккаунта'),
                      content: const Text('Вы уверены, что хотите выйти?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Отмена'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        TextButton(
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Выйти'),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (ctx) => const LoginPage()),
                                  (route) => false);
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                title: "Домашние задания",
                flex: 3,
                childContent: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Всего Д/З',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black54)),
                            const SizedBox(height: 8),
                            Text('$_allHWCounters',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                        height: 80,
                        width: 1,
                        color: Colors.black12), // Уменьшена высота
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 4.0),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly, // Изменено
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildHomeworkGridItem(
                                    'Просрочено', _expiredHW),
                                _buildHomeworkGridItem('Актуально', _currentHW),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildHomeworkGridItem(
                                    'На проверке', _onCheckHW),
                                _buildHomeworkGridItem('Проверено', _checkedHW),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                title: "Успеваемость",
                flex: 3,
                childContent: Row(
                  children: [
                    Expanded(
                      child: _buildMainStatsColumn('Статистика', [
                        _buildMainStatRow('Средний балл: ', '$_avgGradeValue',
                            _getStatGradeColor(_avgGradeValue)),
                        _buildMainStatRow(
                            'Посещаемость: ',
                            '$_attendanceValue%',
                            _getStatAttendanceColor(_attendanceValue)),
                      ]),
                    ),
                    Container(height: 70, width: 1, color: Colors.black12),
                    Expanded(
                      child: _buildMainStatsColumn('Рейтинг', [
                        _buildMainStatRow('В группе: ', '$_groupTopPosition'),
                        _buildMainStatRow('В потоке: ', '$_streamTopPosition'),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                flex: 7,
                childContent: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 8),
                      child: Text('Таблица лидеров',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTabButton('Группа', _isGroupTab, true),
                        const SizedBox(width: 16),
                        _buildTabButton('Поток', !_isGroupTab, false),
                      ],
                    ),
                    Expanded(
                      child: Scrollbar(
                        thickness: 5,
                        radius: const Radius.circular(3),
                        thumbVisibility: true,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: _isGroupTab
                              ? _groupLeaders.length
                              : _streamLeadersFiltered.length +
                                  (_streamLeadersFiltered.length > 3 ? 1 : 0),
                          itemBuilder: (context, index) {
                            final currentLeaders = _isGroupTab
                                ? _groupLeaders
                                : _streamLeadersFiltered;

                            if (!_isGroupTab &&
                                currentLeaders.length > 3 &&
                                index == 3) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: Colors.black26,
                                    indent: 16,
                                    endIndent: 16),
                              );
                            }

                            final actualIndex = (!_isGroupTab &&
                                    currentLeaders.length > 3 &&
                                    index > 3)
                                ? index - 1
                                : index;

                            if (actualIndex >= currentLeaders.length) {
                              return const SizedBox.shrink();
                            }

                            final leader = currentLeaders[actualIndex];

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 4),
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '${leader['position']}.',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      leader['name'],
                                      style: const TextStyle(
                                          fontSize: 15, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${leader['amount']}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                  ),
                                  const SizedBox(width: 4),
                                  Image.asset('assets/images/top-money.png',
                                      width: 18, height: 18),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required int flex, required Widget childContent, String? title}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding:
            title != null ? const EdgeInsets.only(top: 12.0) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((255 * 0.15).round()),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
            Expanded(child: childContent),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkGridItem(String title, int count) {
    Color countColor;
    switch (title) {
      case 'Проверено':
        countColor = const Color(0xFF4CAF50);
        break;
      case 'Просрочено':
        countColor = const Color(0xFFEF5350);
        break;
      case 'Актуально':
        countColor = const Color(0xFF5C6BC0);
        break;
      case 'На проверке':
        countColor = const Color(0xFFFFA726);
        break;
      default:
        countColor = Colors.black;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 11, color: Colors.black54)), // Уменьшен шрифт
        const SizedBox(height: 3), // Уменьшен отступ
        Text('$count',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: countColor)), // Уменьшен шрифт
      ],
    );
  }

  Widget _buildMainStatsColumn(String title, List<Widget> statRows) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          ...statRows,
        ],
      ),
    );
  }

  Widget _buildMainStatRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Color _getStatGradeColor(int grade) {
    if (grade >= 4) {
      return const Color(0xFF4CAF50);
    }
    if (grade >= 3) {
      return const Color(0xFFFFA000);
    }
    return const Color(0xFFEF5350);
  }

  Color _getStatAttendanceColor(int attendance) {
    if (attendance >= 90) {
      return const Color(0xFF4CAF50);
    }
    if (attendance >= 70) {
      return const Color(0xFFFFA000);
    }
    return const Color(0xFFEF5350);
  }

  Widget _buildTabButton(String text, bool isActive, bool isGroupTabForAction) {
    return ElevatedButton(
      onPressed: () => _switchTab(isGroupTabForAction),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isActive ? Theme.of(context).primaryColor : Colors.grey[200],
        foregroundColor: isActive ? Colors.white : Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        elevation: isActive ? 2 : 0,
      ),
      child: Text(text,
          style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14)),
    );
  }
}
