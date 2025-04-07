import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SchedulePage extends StatefulWidget {
  final String authToken;
  final List<dynamic> initialSchedule;

  const SchedulePage({
    super.key,
    required this.authToken,
    required this.initialSchedule,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();
  List<dynamic> scheduleData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    scheduleData = widget.initialSchedule;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchSchedule(); // This will run when page is visible
  }

  Future<void> _fetchSchedule() async {
    setState(() {
      isLoading = true;
    });

    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final scheduleUrl = Uri.parse(
        'https://msapi.top-academy.ru/api/v2/schedule/operations/get-by-date?date_filter=$formattedDate',
      );

      final response = await http.get(
        scheduleUrl,
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      // ignore: avoid_print
      print('Schedule Response Status: ${response.statusCode}');
      // ignore: avoid_print
      print('Schedule Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          scheduleData = jsonResponse['data'] ?? []; // Access the 'data' field
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          scheduleData = []; // Clear data on error
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching schedule: $e');
      setState(() {
        isLoading = false;
        scheduleData = []; // Clear data on error
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2024),
        lastDate: DateTime(2025),
        locale: const Locale('en', 'US'), // Add locale
      );
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
        });
        _fetchSchedule();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error selecting date')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchSchedule,
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : scheduleData.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No schedule for this date'),
                            TextButton(
                              onPressed: _fetchSchedule,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: scheduleData.length,
                        itemBuilder: (context, index) {
                          final lesson = scheduleData[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: Text(
                                '${lesson['lesson_number'] ?? (index + 1)}', // Update field name
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              title: Text(
                                lesson['subject_name'] ?? 'No subject',
                              ), // Update field name
                              subtitle: Text(
                                lesson['teacher_name'] ?? 'No teacher',
                              ), // Update field name
                              trailing: Text(
                                '${lesson['start_time'] ?? '--:--'}',
                              ), // Update field name
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
