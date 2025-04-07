import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:journal_it_top/schedule.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  final List<dynamic> homeworkData;
  final List<dynamic> progressData;
  final List<dynamic> attendanceData;
  final Map<String, dynamic> groupLeaderData;
  final Map<String, dynamic> streamLeaderData;
  final List<dynamic> leaderStreamData;
  final List<dynamic> leaderGroupData;

  const ProfilePage({
    super.key,
    required this.userInfo,
    required this.homeworkData,
    required this.progressData,
    required this.attendanceData,
    required this.groupLeaderData,
    required this.streamLeaderData,
    required this.leaderStreamData,
    required this.leaderGroupData,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isGroupTab = true;

  void _switchTab(bool isGroup) {
    setState(() {
      isGroupTab = isGroup;
    });
  }

  Future<List<dynamic>> _fetchSchedule(String date) async {
    try {
      final scheduleUrl = Uri.parse(
        'https://msapi.top-academy.ru/api/v2/schedule/operations/get-by-date?date_filter=$date',
      );

      final response = await http.get(
        scheduleUrl,
        headers: {
          'Authorization': 'Bearer ${widget.userInfo['token']}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching schedule: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.grey,
        statusBarColor: Colors.transparent,
      ),
    );

    int coins = widget.userInfo['gaming_points'][0]['points'] as int;
    int gems = widget.userInfo['gaming_points'][1]['points'] as int;
    int totalPoints = coins + gems;

    int allHW =
        (widget.homeworkData[5] as Map<String, dynamic>)['counter'] as int;
    int checkedHW =
        (widget.homeworkData[0] as Map<String, dynamic>)['counter'] as int;
    int currentHW =
        (widget.homeworkData[1] as Map<String, dynamic>)['counter'] as int;
    int onCheckHW =
        (widget.homeworkData[3] as Map<String, dynamic>)['counter'] as int;
    int expiredHW =
        (widget.homeworkData[2] as Map<String, dynamic>)['counter'] as int;

    final latestProgress = widget.progressData.isNotEmpty
        ? widget.progressData.last
        : {'points': 0};
    final latestAttendance = widget.attendanceData.isNotEmpty
        ? widget.attendanceData.last
        : {'points': 0};

    int avgGrade = latestProgress['points'] as int;
    int attendance = latestAttendance['points'] as int;

    int groupTop = (widget.groupLeaderData['studentPosition'] as int?) ?? 0;
    int streamTop = (widget.streamLeaderData['studentPosition'] as int?) ?? 0;

    String groupName = widget.leaderGroupData.isNotEmpty
        ? widget.leaderGroupData[0]['full_name']?.toString() ?? 'N/A'
        : 'N/A';
    int groupAmount = widget.leaderGroupData.isNotEmpty
        ? (widget.leaderGroupData[0]['amount'] as int?) ?? 0
        : 0;
    int groupPosition = widget.leaderGroupData.isNotEmpty
        ? (widget.leaderGroupData[0]['position'] as int?) ?? 0
        : 0;
    String streamName = widget.leaderStreamData.isNotEmpty
        ? widget.leaderStreamData[0]['full_name']?.toString() ?? 'N/A'
        : 'N/A';
    int streamAmount = widget.leaderStreamData.isNotEmpty
        ? (widget.leaderStreamData[0]['amount'] as int?) ?? 0
        : 0;
    int streamPosition = widget.leaderStreamData.isNotEmpty
        ? (widget.leaderStreamData[0]['position'] as int?) ?? 0
        : 0;

    List<Map<String, dynamic>> groupLeaders = [];
    for (var leader in widget.leaderGroupData) {
      groupLeaders.add({
        'name': leader['full_name']?.toString() ?? 'N/A',
        'amount': (leader['amount'] as int?) ?? 0,
        'position': (leader['position'] as int?) ?? 0,
      });
    }

    List<Map<String, dynamic>> streamLeaders = [];
    for (var leader in widget.leaderStreamData) {
      streamLeaders.add({
        'name': leader['full_name']?.toString() ?? 'N/A',
        'amount': (leader['amount'] as int?) ?? 0,
        'position': (leader['position'] as int?) ?? 0,
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      extendBody: false,
      appBar: AppBar(
        title: Text(widget.userInfo['full_name'] ?? 'Profile Page'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Container(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('$totalPoints'),
                            SizedBox(width: 10),
                            Image.asset(
                              'assets/images/top-money.png',
                              width: 24,
                              height: 24,
                            ),
                            Text(' $coins'),
                            SizedBox(width: 10),
                            Image.asset(
                              'assets/images/top-coin.png',
                              width: 24,
                              height: 24,
                            ),
                            Text(' $gems'),
                            SizedBox(width: 10),
                            Image.asset(
                              'assets/images/top-gem.png',
                              width: 24,
                              height: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Text('Schedule'),
              onTap: () async {
                final String today = DateFormat(
                  'yyyy-MM-dd',
                ).format(DateTime.now());
                final scheduleData = await _fetchSchedule(today);

                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => SchedulePage(
                        initialSchedule: scheduleData,
                        authToken: widget.userInfo['authToken'],
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () {
                // Handle logout tap
              },
            ),
          ],
        ),
      ),
      drawerScrimColor: Colors.black.withOpacity(0.5),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.7,
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: EdgeInsets.only(bottom: 8)),
              Expanded(
                flex: 3, // Set flex to 3
                child: Container(
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 231, 231, 231),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'All Homework',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '$allHW',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 110, width: 1, color: Colors.black26),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildGridItem('Expired', expiredHW),
                                _buildGridItem('Current', currentHW),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildGridItem('On Check', onCheckHW),
                                _buildGridItem('Checked', checkedHW),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3, // Set flex to 3
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 231, 231, 231),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // Statistics Column
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Statistics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Average grade: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '$avgGrade',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getGradeColor(avgGrade),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Attendance: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '$attendance%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getAttendanceColor(attendance),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Vertical Divider
                      Container(height: 80, width: 1, color: Colors.black26),
                      // Leaderboard Column
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Leaderboard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Group: $groupTop',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Stream: $streamTop',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 7, // Set flex to 5 for 5/3 ratio compared to others
                child: Container(
                  margin: EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 231, 231, 231),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          'Leaderboard',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTab('Group', isGroupTab),
                          SizedBox(width: 16),
                          _buildTab('Stream', !isGroupTab),
                        ],
                      ),
                      Expanded(
                        child: Scrollbar(
                          thickness: 6,
                          radius: Radius.circular(3),
                          thumbVisibility:
                              true, // Makes the scrollbar always visible
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: isGroupTab
                                ? groupLeaders.length
                                : streamLeaders.length,
                            itemBuilder: (context, index) {
                              // Replace the dashes Text widget with a Container
                              if (!isGroupTab && index == 3) {
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Container(
                                    height: 1,
                                    color: Colors.black26,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                  ),
                                );
                              }

                              // Skip the actual 4th place data in stream tab
                              final actualIndex =
                                  !isGroupTab && index > 4 ? index - 1 : index;
                              final leader = isGroupTab
                                  ? groupLeaders[index]
                                  : streamLeaders[actualIndex];

                              // Return normal list item
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.black12,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left side: position and name
                                    Row(
                                      children: [
                                        Text(
                                          '${leader['position']}. ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.5,
                                          ),
                                          child: Text(
                                            leader['name'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Right side: amount and icon
                                    Row(
                                      children: [
                                        Text(
                                          '${leader['amount']}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Image.asset(
                                          'assets/images/top-money.png',
                                          width: 20,
                                          height: 20,
                                        ),
                                      ],
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(String title, int count) {
    Color countColor;
    switch (title) {
      case 'Checked':
        countColor = Color(0xFF4CAF50);
        break;
      case 'Expired':
        countColor = Color(0xFFEF5350);
        break;
      case 'Current':
        countColor = Color.fromARGB(255, 148, 93, 185);
        break;
      case 'On Check':
        countColor = Color.fromARGB(255, 194, 166, 42);
        break;
      default:
        countColor = Colors.black;
    }

    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.black54)),
        SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: countColor,
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(int grade) {
    if (grade >= 4) return Color(0xFF4CAF50);
    if (grade >= 3) return Color(0xFFFDD835);
    return Color(0xFFEF5350);
  }

  Color _getAttendanceColor(int attendance) {
    if (attendance >= 90) return Color(0xFF4CAF50);
    if (attendance >= 70) return Color(0xFFFDD835);
    return Color(0xFFEF5350);
  }

  Widget _buildTab(String text, bool isActive) {
    return GestureDetector(
      onTap: () => _switchTab(text == 'Group'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black87 : Colors.black54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
