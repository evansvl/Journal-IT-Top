import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:journal_it_top/models/homework_item.dart';
import 'package:journal_it_top/models/schedule_lesson.dart';
import 'package:journal_it_top/models/lesson_visit_mark.dart';
// import 'package:url_launcher/url_launcher.dart'; // Закомментировано, если _launchUrlInApp не используется

class SchedulePage extends StatefulWidget {
  final String authToken;
  final List<dynamic> initialSchedule;
  final Future<List<HomeworkItem>> allHomeworkFuture;
  final Future<List<LessonVisitMark>> allLessonVisitsFuture;

  const SchedulePage({
    super.key,
    required this.authToken,
    required this.initialSchedule,
    required this.allHomeworkFuture,
    required this.allLessonVisitsFuture,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with WidgetsBindingObserver {
  // <--- Добавлено with WidgetsBindingObserver
  DateTime _selectedDate = DateTime.now();
  List<ScheduleLesson> _scheduleLessons = [];
  bool _isLoadingSchedule = false;
  List<HomeworkItem>? _loadedHomework;
  List<LessonVisitMark>? _loadedVisitsAndMarks;
  bool _areAdditionalDataLoading = true;
  bool _additionalDataError = false;

  // Ключ для принудительного обновления BottomSheet, если простой setState не поможет
  // Key _bottomSheetContentKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Подписываемся

    _selectedDate = DateTime.now();

    _scheduleLessons =
        _processRawScheduleData(widget.initialSchedule, null, null);
    _loadAllAdditionalData();

    bool shouldFetchApiSchedule = true;
    if (_scheduleLessons.isNotEmpty) {
      try {
        if (DateUtils.isSameDay(
            _scheduleLessons.first.dateTime, _selectedDate)) {
          shouldFetchApiSchedule = false;
        } else {
          _scheduleLessons = [];
        }
      } catch (e) {
        // ignore: avoid_print
        print("Error comparing dates in initState: $e");
        _scheduleLessons = [];
      }
    } else {
      _scheduleLessons = [];
    }

    if (shouldFetchApiSchedule) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchScheduleForSelectedDate();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Отписываемся
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // ignore: avoid_print
    print('AppLifecycleState changed to: $state for SchedulePage');
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        // ignore: avoid_print
        print('SchedulePage resumed, forcing UI refresh.');
        setState(() {
          // Простого setState может быть достаточно для перерисовки
          // Если проблема с текстом именно в BottomSheet и он уже открыт,
          // то этот setState может не повлиять на уже построенный BottomSheet.
          // В таком случае, если BottomSheet открывается заново после resume, то все должно быть ок.
          // Если BottomSheet остается открытым при сворачивании (маловероятно для модального),
          // то обновление его контента сложнее и может потребовать ValueNotifier или другой подход.
          // _bottomSheetContentKey = UniqueKey(); // Можно попробовать, если текст в BottomSheet
        });
      }
    }
  }

  Future<void> _loadAllAdditionalData() async {
    setState(() {
      _areAdditionalDataLoading = true;
      _additionalDataError = false;
    });
    try {
      final results = await Future.wait([
        widget.allHomeworkFuture,
        widget.allLessonVisitsFuture,
      ]);

      final homework = results[0] as List<HomeworkItem>?;
      final visitsAndMarks = results[1] as List<LessonVisitMark>?;

      if (mounted) {
        setState(() {
          _loadedHomework = homework;
          _loadedVisitsAndMarks = visitsAndMarks;
          _areAdditionalDataLoading = false;
          _additionalDataError = false;
          _updateScheduleLessonsWithAdditionalData();
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error resolving allHomeworkFuture or allLessonVisitsFuture: $e");
      if (mounted) {
        setState(() {
          _additionalDataError = true;
          _areAdditionalDataLoading = false;
          _loadedHomework = _loadedHomework ?? [];
          _loadedVisitsAndMarks = _loadedVisitsAndMarks ?? [];
          _updateScheduleLessonsWithAdditionalData();
        });
      }
    }
  }

  void _updateScheduleLessonsWithAdditionalData() {
    List<Map<String, dynamic>> currentLessonsAsRaw = [];
    // Если _scheduleLessons пуст, но initialSchedule не пуст, используем initialSchedule
    // Это важно, если _loadAllAdditionalData завершится до первой загрузки расписания по API
    final sourceForRaw = _scheduleLessons.isNotEmpty
        ? _scheduleLessons
        : widget.initialSchedule
            .map(
                (item) => ScheduleLesson.fromJson(item as Map<String, dynamic>))
            .toList();

    for (var lesson in sourceForRaw) {
      currentLessonsAsRaw.add({
        'date': DateFormat('yyyy-MM-dd').format(lesson.dateTime),
        'lesson': lesson.lessonNumber,
        'started_at': lesson.startedAt,
        'finished_at': lesson.finishedAt,
        'teacher_name': lesson.teacherName,
        'subject_name': lesson.subjectName,
        'room_name': lesson.roomName,
      });
    }
    _scheduleLessons = _processRawScheduleData(
        currentLessonsAsRaw, _loadedHomework, _loadedVisitsAndMarks);
  }

  List<ScheduleLesson> _processRawScheduleData(List<dynamic> rawScheduleData,
      List<HomeworkItem>? homeworkList, List<LessonVisitMark>? visitMarkList) {
    final lessons = rawScheduleData.map((item) {
      return ScheduleLesson.fromJson(item as Map<String, dynamic>);
    }).toList();

    for (var lesson in lessons) {
      if (homeworkList != null) {
        lesson.relatedHomework = _findHomeworkForLesson(lesson, homeworkList);
      }
      if (visitMarkList != null) {
        lesson.visitMarkData = _findVisitMarkForLesson(lesson, visitMarkList);
      }
    }
    return lessons;
  }

  Future<void> _fetchScheduleForSelectedDate() async {
    if (_isLoadingSchedule) return;
    setState(() {
      _isLoadingSchedule = true;
    });
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final scheduleUrl = Uri.parse(
        'https://msapi.top-academy.ru/api/v2/schedule/operations/get-by-date?date_filter=$formattedDate',
      );
      // ignore: avoid_print
      print('Fetching schedule (SchedulePage) for $formattedDate...');
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
      if (mounted) {
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          List<dynamic> rawScheduleApiData = [];
          if (jsonResponse is Map<String, dynamic> &&
              jsonResponse.containsKey('data')) {
            rawScheduleApiData = List<dynamic>.from(jsonResponse['data'] ?? []);
          } else if (jsonResponse is List) {
            rawScheduleApiData = List<dynamic>.from(jsonResponse);
          }
          setState(() {
            _scheduleLessons = _processRawScheduleData(
                rawScheduleApiData, _loadedHomework, _loadedVisitsAndMarks);
          });
        } else {
          _scheduleLessons = [];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Ошибка загрузки расписания (код: ${response.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _scheduleLessons = [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети при загрузке расписания: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSchedule = false;
        });
      }
    }
  }

  HomeworkItem? _findHomeworkForLesson(
      ScheduleLesson lesson, List<HomeworkItem> homeworkList) {
    HomeworkItem? bestMatch;
    for (var hw in homeworkList) {
      if (hw.subjectName.trim().toLowerCase() ==
          lesson.subjectName.trim().toLowerCase()) {
        DateTime hwCreationDate = hw.creationDateTime;
        DateTime hwCompletionDate = hw.completionDateTime;
        DateTime lessonDate = lesson.dateTime;
        bool isRelevantDate = DateUtils.isSameDay(hwCreationDate, lessonDate) ||
            (lessonDate.isAfter(hwCreationDate) &&
                lessonDate
                    .isBefore(hwCompletionDate.add(const Duration(days: 2))));
        if (isRelevantDate) {
          if (hw.status == 3 || hw.status == 0) {
            if (bestMatch == null ||
                (bestMatch.status != 3 && bestMatch.status != 0) ||
                (hwCreationDate.isAfter(bestMatch.creationDateTime) &&
                    hw.status == 3) ||
                (hw.status == 3 && bestMatch.status == 0)) {
              bestMatch = hw;
            }
          } else if (bestMatch == null && (hw.status == 1 || hw.status == 2)) {
            bestMatch = hw;
          } else if (bestMatch != null &&
              (bestMatch.status != 3 && bestMatch.status != 0) &&
              (hw.status == 1 || hw.status == 2)) {
            if (hw.completionDateTime.isAfter(bestMatch.completionDateTime)) {
              bestMatch = hw;
            }
          }
        }
      }
    }
    return bestMatch;
  }

  LessonVisitMark? _findVisitMarkForLesson(
      ScheduleLesson lesson, List<LessonVisitMark> visitMarkList) {
    for (var visitMark in visitMarkList) {
      if (DateUtils.isSameDay(visitMark.visitDateTime, lesson.dateTime) &&
          visitMark.lessonNumber == lesson.lessonNumber &&
          visitMark.subjectName.trim().toLowerCase() ==
              lesson.subjectName.trim().toLowerCase()) {
        return visitMark;
      }
    }
    return null;
  }

  // Future<void> _launchUrlInApp(String urlString) async { ... }

  Future<void> _selectDateFromPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
      locale: const Locale('ru', 'RU'),
      helpText: 'Выберите дату',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
      builder: (context, child) {
        /* ... Theme ... */ return child!;
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _scheduleLessons = [];
      });
      _fetchScheduleForSelectedDate();
    }
  }

  // ignore: unused_element
  void _showLessonDetails(BuildContext context, ScheduleLesson lesson) {
    // final HomeworkItem? homework = lesson.relatedHomework; // Закомментировано, т.к. ДЗ временно не отображается
    // final LessonVisitMark? visitMark = lesson.visitMarkData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      // key: _bottomSheetContentKey, // Можно попробовать использовать ключ здесь, если setState в didChangeAppLifecycleState не помогает
      builder: (BuildContext bc) {
        final bottomSystemPadding = MediaQuery.of(bc).padding.bottom;

        // Собираем виджеты для отображения в BottomSheet
        List<Widget> detailsWidgets = [];
        detailsWidgets.add(Center(
          child: Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
          ),
        ));
        detailsWidgets.add(Text(lesson.subjectName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)));
        detailsWidgets.add(const SizedBox(height: 8));
        detailsWidgets.add(Row(children: [
          Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
              '${lesson.startedAt.length > 5 ? lesson.startedAt.substring(0, 5) : lesson.startedAt} - ${lesson.finishedAt.length > 5 ? lesson.finishedAt.substring(0, 5) : lesson.finishedAt}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        ]));
        detailsWidgets.add(const SizedBox(height: 4));
        detailsWidgets.add(Row(children: [
          Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(lesson.teacherName,
              style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        ]));
        if (lesson.roomName.isNotEmpty) {
          detailsWidgets.add(const SizedBox(height: 4));
          detailsWidgets.add(Row(children: [
            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(lesson.roomName,
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          ]));
        }

        // Временно скрываем ДЗ и оценки (или показываем заглушки/статус загрузки)
        // ... (здесь был код для homework и visitMark)

        return Padding(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: 20.0 + bottomSystemPadding,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: detailsWidgets,
            ),
          ),
        );
      },
    );
  }

  Color _getMarkColor(int mark) {
    if (mark >= 4) {
      return Colors.green;
    } else if (mark == 3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDayOfWeek =
        DateFormat('EEEE', 'ru_RU').format(_selectedDate);
    formattedDayOfWeek =
        formattedDayOfWeek[0].toUpperCase() + formattedDayOfWeek.substring(1);

    return Scaffold(
      appBar: AppBar(title: const Text('Расписание занятий')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((255 * 0.15).round()),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                )
              ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: _isLoadingSchedule ? null : () {/* ... */},
                    tooltip: 'Предыдущий день',
                  ),
                  GestureDetector(
                    onTap: _isLoadingSchedule
                        ? null
                        : () => _selectDateFromPicker(context),
                    child: Column(/* ... */),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                    onPressed: _isLoadingSchedule ? null : () {/* ... */},
                    tooltip: 'Следующий день',
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchScheduleForSelectedDate,
                color: Theme.of(context).primaryColor,
                child: (_isLoadingSchedule && _scheduleLessons.isEmpty)
                    ? const Center(child: CircularProgressIndicator())
                    : _scheduleLessons.isEmpty
                        ? LayoutBuilder(builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.event_busy_outlined,
                                            size: 60, color: Colors.grey),
                                        const SizedBox(height: 16),
                                        Text(
                                            _isLoadingSchedule
                                                ? 'Загрузка расписания...'
                                                : 'Нет занятий на эту дату',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black54)),
                                        if (_areAdditionalDataLoading)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    )),
                                                SizedBox(width: 8),
                                                Text('Загрузка ДЗ/оценок...'),
                                              ],
                                            ),
                                          )
                                        else if (_additionalDataError)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: Text(
                                                'Не удалось загрузить ДЗ/оценки.',
                                                style: TextStyle(
                                                    color: Colors.orange)),
                                          ),
                                        if (!_isLoadingSchedule)
                                          TextButton(
                                            onPressed: () {/* ... */},
                                            child: const Text('Обновить'),
                                          )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            itemCount: _scheduleLessons.length,
                            itemBuilder: (context, index) {
                              final lesson = _scheduleLessons[index];
                              List<Widget> lessonMarksWidgets = [];

                              if (!_areAdditionalDataLoading &&
                                  lesson.visitMarkData != null &&
                                  lesson.visitMarkData!.hasAnyMark) {
                                for (var entry
                                    in lesson.visitMarkData!.allMarks) {
                                  lessonMarksWidgets.add(Padding(
                                    padding: const EdgeInsets.only(
                                        right: 4.0, top: 2.0),
                                    child: Chip(
                                      label: Text(
                                          '${entry.key.substring(0, 1)}:${entry.value}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black87)),
                                      backgroundColor: _getMarkColor(
                                              entry.value)
                                          .withOpacity(
                                              0.15), // Используем getMarkColor здесь
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ));
                                }
                              } else if (_areAdditionalDataLoading) {
                                lessonMarksWidgets.add(const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5)));
                              }

                              return Card(/* ... Карточка урока ... */);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
