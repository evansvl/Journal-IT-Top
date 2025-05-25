class HomeworkItem {
  final int id;
  final String subjectName; // name_spec
  final String teacherName; // fio_teach
  final String theme;
  final String completionDate; // completion_time (дата сдачи)
  final String creationDate; // creation_time (дата выдачи)
  final String? filePath; // file_path (файл самого задания)
  final String? comment; // comment (комментарий к заданию от преподавателя)
  final int
      status; // 0 - просрочено, 1 - проверено, 2 - сдано, 3 - текущие, 5 - удалено

  final int? studentMark;
  final String? studentAnswer;
  final String? studentFilePath;
  final String?
      teacherReviewTextComment; // Текстовый комментарий преподавателя к работе студента
  final String? coverImageUrl;

  HomeworkItem({
    required this.id,
    required this.subjectName,
    required this.teacherName,
    required this.theme,
    required this.completionDate,
    required this.creationDate,
    this.filePath,
    this.comment,
    required this.status,
    this.studentMark,
    this.studentAnswer,
    this.studentFilePath,
    this.teacherReviewTextComment,
    this.coverImageUrl,
  });

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    final homeworkStud = json['homework_stud'] as Map<String, dynamic>?;
    final homeworkCommentMap =
        json['homework_comment'] as Map<String, dynamic>?;

    return HomeworkItem(
      id: json['id'] as int,
      subjectName: json['name_spec'] as String? ?? 'Не указано',
      teacherName: json['fio_teach'] as String? ?? 'Не указан',
      theme: json['theme'] as String? ?? 'Без темы',
      completionDate: json['completion_time'] as String,
      creationDate: json['creation_time'] as String,
      filePath: json['file_path'] as String?,
      comment: json['comment'] as String?,
      status: json['status'] as int,
      studentMark: homeworkStud?['mark'] as int?,
      studentAnswer: homeworkStud?['stud_answer'] as String?,
      studentFilePath: homeworkStud?['file_path'] as String?,
      teacherReviewTextComment: homeworkCommentMap?['text_comment'] as String?,
      coverImageUrl: json['cover_image'] as String?,
    );
  }

  DateTime get completionDateTime {
    try {
      return DateTime.parse(completionDate);
    } catch (e) {
      return DateTime(1970);
    }
  }

  DateTime get creationDateTime {
    try {
      return DateTime.parse(creationDate);
    } catch (e) {
      return DateTime(1970);
    }
  }

  String get statusText {
    switch (status) {
      case 0:
        return "Просрочено";
      case 1:
        return "Проверено";
      case 2:
        return "Сдано";
      case 3:
        return "Текущее";
      case 5:
        return "Удалено преподавателем";
      default:
        return "Неизвестный статус";
    }
  }
}
