class LessonVisitMark {
  final String dateVisit;
  final int lessonNumber;
  final int statusWas; // 1 - был, 0 - не был (предположение)
  final int subjectId; // spec_id
  final String subjectName; // spec_name
  final String? lessonTheme;
  final int? controlWorkMark;
  final int? homeWorkMark;
  final int? labWorkMark;
  final int? classWorkMark;

  LessonVisitMark({
    required this.dateVisit,
    required this.lessonNumber,
    required this.statusWas,
    required this.subjectId,
    required this.subjectName,
    this.lessonTheme,
    this.controlWorkMark,
    this.homeWorkMark,
    this.labWorkMark,
    this.classWorkMark,
  });

  factory LessonVisitMark.fromJson(Map<String, dynamic> json) {
    return LessonVisitMark(
      dateVisit: json['date_visit'] as String,
      lessonNumber: json['lesson_number'] as int,
      statusWas: json['status_was'] as int,
      subjectId: json['spec_id'] as int,
      subjectName: json['spec_name'] as String? ?? 'Не указано',
      lessonTheme: json['lesson_theme'] as String?,
      controlWorkMark: json['control_work_mark'] as int?,
      homeWorkMark: json['home_work_mark'] as int?,
      labWorkMark: json['lab_work_mark'] as int?,
      classWorkMark: json['class_work_mark'] as int?,
    );
  }

  DateTime get visitDateTime {
    try {
      return DateTime.parse(dateVisit);
    } catch (e) {
      return DateTime(1970);
    }
  }

  // Собираем все существующие оценки в список для удобного отображения
  List<MapEntry<String, int>> get allMarks {
    final marks = <MapEntry<String, int>>[];
    if (classWorkMark != null)
      // ignore: curly_braces_in_flow_control_structures
      marks.add(MapEntry("Работа на уроке", classWorkMark!));
    if (homeWorkMark != null)
      // ignore: curly_braces_in_flow_control_structures
      marks.add(MapEntry("Дом. задание", homeWorkMark!));
    if (labWorkMark != null) marks.add(MapEntry("Лаб. работа", labWorkMark!));
    if (controlWorkMark != null)
      // ignore: curly_braces_in_flow_control_structures
      marks.add(MapEntry("Контр. работа", controlWorkMark!));
    return marks;
  }

  bool get hasAnyMark =>
      controlWorkMark != null ||
      homeWorkMark != null ||
      labWorkMark != null ||
      classWorkMark != null;
}
