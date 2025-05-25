import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:journal_it_top/models/homework_item.dart';
import 'package:journal_it_top/models/schedule_lesson.dart';
import 'package:journal_it_top/models/lesson_visit_mark.dart';
// import 'package:url_launcher/url_launcher.dart'; // Закомментировано, т.к. _launchUrlInApp закомментирован

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

class _SchedulePageState extends State<SchedulePage> {
  DateTime _selectedDate = DateTime.now();
  List<ScheduleLesson> _scheduleLessons = [];
  bool _isLoadingSchedule = false;
  List<HomeworkItem>? _loadedHomework;
  List<LessonVisitMark>? _loadedVisitsAndMarks;
  bool _areAdditionalDataLoading = true;
  bool _additionalDataError = false;

  @override
  void initState() {
    super.initState();
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
    for (var lesson in _scheduleLessons) {
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

    if (currentLessonsAsRaw.isEmpty &&
        widget.initialSchedule.isNotEmpty &&
        _loadedHomework != null &&
        _loadedVisitsAndMarks != null) {
      // ignore: avoid_print
      print("Updating with initialSchedule data after additional data load.");
      _scheduleLessons = _processRawScheduleData(
          widget.initialSchedule, _loadedHomework, _loadedVisitsAndMarks);
    } else {
      _scheduleLessons = _processRawScheduleData(
          currentLessonsAsRaw, _loadedHomework, _loadedVisitsAndMarks);
    }
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
      // ignore: avoid_print
      print('Error fetching schedule: $e');
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
            // Текущее или Просрочено (но еще может быть актуально к показу)
            if (bestMatch == null ||
                (bestMatch.status != 3 &&
                    bestMatch.status !=
                        0) || // Если текущее лучше, чем не (текущее и не просроченное)
                (hwCreationDate.isAfter(bestMatch.creationDateTime) &&
                    hw.status == 3) || // Более новое текущее
                (hw.status == 3 && bestMatch.status == 0)) {
              // Текущее лучше просроченного
              bestMatch = hw;
            }
          } else if (bestMatch == null && (hw.status == 1 || hw.status == 2)) {
            // Проверено или Сдано (если другого нет)
            bestMatch = hw;
          } else if (bestMatch != null &&
              (bestMatch.status != 3 &&
                  bestMatch.status !=
                      0) && // Если текущий bestMatch не приоритетный
              (hw.status == 1 || hw.status == 2)) {
            // А новое ДЗ - проверено или сдано
            // Предпочитаем более позднее по дате сдачи
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).primaryColor,
                  onPrimary: Colors.white,
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
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

  void _showLessonDetails(BuildContext context, ScheduleLesson lesson) {
    final HomeworkItem? homework = lesson.relatedHomework;
    final LessonVisitMark? visitMark = lesson.visitMarkData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bc) {
        final bottomSystemPadding = MediaQuery.of(bc).padding.bottom;
        List<Widget> detailsWidgets = [];

        // Информация об уроке
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

        // Информация о посещении (добавлено сюда)
        if (visitMark != null) {
          String visitStatusText;
          Color visitStatusColor;
          switch (visitMark.statusWas) {
            case 0:
              visitStatusText = "Отсутствовал(а)";
              visitStatusColor = Colors.red;
              break;
            case 1:
              visitStatusText = "Присутствовал(а)";
              visitStatusColor = Colors.green;
              break;
            case 2:
              visitStatusText = "Опоздал(а)";
              visitStatusColor = Colors.orange;
              break;
            default:
              visitStatusText = "Статус неизвестен";
              visitStatusColor = Colors.grey;
          }
          detailsWidgets.add(const SizedBox(height: 10));
          detailsWidgets.add(Row(children: [
            Icon(Icons.event_available_outlined,
                size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text("Посещение: ",
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            Text(visitStatusText,
                style: TextStyle(
                    fontSize: 16,
                    color: visitStatusColor,
                    fontWeight: FontWeight.bold)),
          ]));
        }

        detailsWidgets.add(const Divider(height: 30, thickness: 1));

        // Отображение ДЗ
        if (_areAdditionalDataLoading && _loadedHomework == null) {
          detailsWidgets.add(const Text('Домашнее задание:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)));
          detailsWidgets.add(const SizedBox(height: 8));
          detailsWidgets.add(const Row(children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 8),
            Text("Загрузка ДЗ...")
          ]));
        } else if (_additionalDataError && _loadedHomework == null) {
          detailsWidgets.add(const Text('Домашнее задание:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)));
          detailsWidgets.add(const SizedBox(height: 8));
          detailsWidgets.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Не удалось загрузить данные по ДЗ.',
                  style: TextStyle(fontSize: 15)),
            ),
          );
        } else if (homework != null) {
          detailsWidgets.add(const Text('Домашнее задание:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)));
          detailsWidgets.add(const SizedBox(height: 8));
          if (homework.theme.isNotEmpty &&
              homework.theme.toLowerCase() != "null") {
            detailsWidgets.add(Text("Тема: ${homework.theme}",
                style: const TextStyle(
                    fontSize: 15, fontStyle: FontStyle.italic)));
          }
          if (homework.comment != null && homework.comment!.isNotEmpty) {
            detailsWidgets.add(Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text("Описание задания: ${homework.comment}",
                  style: const TextStyle(fontSize: 15)),
            ));
          }
          if (homework.teacherReviewTextComment != null &&
              homework.teacherReviewTextComment!.isNotEmpty) {
            detailsWidgets.add(Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                  "Комментарий преподавателя (к вашей работе): ${homework.teacherReviewTextComment}",
                  style: TextStyle(fontSize: 15, color: Colors.blue[700])),
            ));
          }
          detailsWidgets.add(Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text("Статус: ${homework.statusText}",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _getHomeworkStatusColor(homework.status))),
          ));
        } else if (_loadedHomework != null) {
          detailsWidgets.add(const Text('Домашнее задание:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)));
          detailsWidgets.add(const SizedBox(height: 8));
          detailsWidgets.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8)),
              child: const Text(
                  'Домашнее задание для этого урока не найдено или не выдано.',
                  style: TextStyle(fontSize: 15)),
            ),
          );
        }
        detailsWidgets.add(const SizedBox(height: 20));

        // Отображение Оценок
        if (_areAdditionalDataLoading && _loadedVisitsAndMarks == null) {
          detailsWidgets.add(const Text('Оценки за занятие:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)));
          detailsWidgets.add(const SizedBox(height: 8));
          detailsWidgets.add(const Row(children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 8),
            Text("Загрузка оценок...")
          ]));
        } else if (_additionalDataError && _loadedVisitsAndMarks == null) {
          detailsWidgets.add(const Text('Оценки за занятие:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)));
          detailsWidgets.add(const SizedBox(height: 8));
          detailsWidgets.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Не удалось загрузить данные по оценкам.',
                  style: TextStyle(fontSize: 15)),
            ),
          );
        } else if (visitMark != null && visitMark.hasAnyMark) {
          detailsWidgets.add(const Text('Оценки за занятие:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)));
          detailsWidgets.add(const SizedBox(height: 8));
          for (var entry in visitMark.allMarks) {
            detailsWidgets.add(Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${entry.key}:', style: const TextStyle(fontSize: 15)),
                  Text('${entry.value}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getMarkColor(entry.value))),
                ],
              ),
            ));
          }
        } else if (_loadedVisitsAndMarks != null) {
          detailsWidgets.add(const Text('Оценки за занятие:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)));
          detailsWidgets.add(const SizedBox(height: 8));
          detailsWidgets.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Оценки за этот урок пока не выставлены.',
                  style: TextStyle(fontSize: 15)),
            ),
          );
        }

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
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ...detailsWidgets,
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getHomeworkStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 5:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Color _getMarkColor(int mark) {
    if (mark >= 4) return Colors.green;
    if (mark == 3) return Colors.orange;
    if (mark <= 2 && mark >= 1) return Colors.red;
    return Colors.black;
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
                    onPressed: _isLoadingSchedule
                        ? null
                        : () {
                            setState(() {
                              _selectedDate = _selectedDate
                                  .subtract(const Duration(days: 1));
                              _scheduleLessons = [];
                            });
                            _fetchScheduleForSelectedDate();
                          },
                    tooltip: 'Предыдущий день',
                  ),
                  GestureDetector(
                    onTap: _isLoadingSchedule
                        ? null
                        : () => _selectDateFromPicker(context),
                    child: Column(
                      children: [
                        Text(
                          formattedDayOfWeek,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d MMMM yyyy', 'ru_RU')
                              .format(_selectedDate),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                    onPressed: _isLoadingSchedule
                        ? null
                        : () {
                            setState(() {
                              _selectedDate =
                                  _selectedDate.add(const Duration(days: 1));
                              _scheduleLessons = [];
                            });
                            _fetchScheduleForSelectedDate();
                          },
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
                                            onPressed: () {
                                              _fetchScheduleForSelectedDate();
                                              if (_areAdditionalDataLoading ||
                                                  _additionalDataError) {
                                                _loadAllAdditionalData();
                                              }
                                            },
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

                              // Определение цвета фона карточки
                              Color? cardBackgroundColor;
                              if (lesson.visitMarkData != null) {
                                switch (lesson.visitMarkData!.statusWas) {
                                  case 0: // Не был
                                    cardBackgroundColor = Colors.red[100];
                                    break;
                                  case 2: // Опоздал
                                    cardBackgroundColor = Colors.orange[100];
                                    break;
                                  // case 1: // Был - фон остается стандартным
                                }
                              }

                              if (lesson.visitMarkData != null &&
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
                                      backgroundColor:
                                          _getMarkColor(entry.value)
                                              .withOpacity(0.15),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ));
                                }
                              } else if (_areAdditionalDataLoading &&
                                  _loadedVisitsAndMarks == null) {
                                lessonMarksWidgets.add(const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5)));
                              }

                              return Card(
                                color:
                                    cardBackgroundColor, // <--- ПРИМЕНЯЕМ ЦВЕТ ЗДЕСЬ
                                elevation: 1.0,
                                margin: const EdgeInsets.only(bottom: 10.0),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: InkWell(
                                  onTap: () {
                                    _showLessonDetails(context, lesson);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0, vertical: 12.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 70,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                lesson.lessonNumber.toString(),
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .primaryColorDark),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                lesson.startedAt.length > 5
                                                    ? lesson.startedAt
                                                        .substring(0, 5)
                                                    : lesson.startedAt,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black54,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              Text(
                                                lesson.finishedAt.length > 5
                                                    ? lesson.finishedAt
                                                        .substring(0, 5)
                                                    : lesson.finishedAt,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const SizedBox(
                                          height: 70,
                                          child: VerticalDivider(
                                              width: 1,
                                              thickness: 1,
                                              color: Colors.black12),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lesson.subjectName,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              if (lesson
                                                  .teacherName.isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Row(children: [
                                                  const Icon(
                                                      Icons.person_outline,
                                                      size: 14,
                                                      color: Colors.black54),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                      child: Text(
                                                          lesson.teacherName,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .black54),
                                                          overflow: TextOverflow
                                                              .ellipsis)),
                                                ]),
                                              ],
                                              if (lesson
                                                  .roomName.isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Row(children: [
                                                  const Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      size: 14,
                                                      color: Colors.black54),
                                                  const SizedBox(width: 5),
                                                  Text(lesson.roomName,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.black54)),
                                                ]),
                                              ],
                                              if (lessonMarksWidgets
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Wrap(
                                                    spacing: 2.0,
                                                    runSpacing: 2.0,
                                                    children:
                                                        lessonMarksWidgets),
                                              ]
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
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
