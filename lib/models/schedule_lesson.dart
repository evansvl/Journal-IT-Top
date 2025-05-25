import 'package:journal_it_top/models/homework_item.dart';
import 'package:journal_it_top/models/lesson_visit_mark.dart';

class ScheduleLesson {
  final String date;
  final int lessonNumber;
  final String startedAt;
  final String finishedAt;
  final String teacherName;
  final String subjectName;
  final String roomName;
  HomeworkItem? relatedHomework;
  LessonVisitMark? visitMarkData; // <--- НОВОЕ ПОЛЕ

  ScheduleLesson({
    required this.date,
    required this.lessonNumber,
    required this.startedAt,
    required this.finishedAt,
    required this.teacherName,
    required this.subjectName,
    required this.roomName,
    this.relatedHomework,
    this.visitMarkData, // <--- В конструктор
  });

  factory ScheduleLesson.fromJson(Map<String, dynamic> json) {
    return ScheduleLesson(
      date: json['date'] as String,
      lessonNumber: json['lesson'] as int,
      startedAt: json['started_at'] as String? ?? '--:--',
      finishedAt: json['finished_at'] as String? ?? '--:--',
      teacherName: json['teacher_name'] as String? ?? 'Не указан',
      subjectName: json['subject_name'] as String? ?? 'Не указан',
      roomName: json['room_name'] as String? ?? '',
    );
  }

  DateTime get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime(1970);
    }
  }
}
