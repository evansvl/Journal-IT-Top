import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:journal_it_top/models/homework_item.dart';
import 'package:journal_it_top/models/lesson_visit_mark.dart';

class ApiService {
  final String _baseUrl = 'https://msapi.top-academy.ru/api/v2';
  final String _authToken;
  final int _maxPagesPerStatus = 70;

  ApiService({required String authToken}) : _authToken = authToken;

  Map<String, String> get headers => {
        "Accept": "application/json, text/plain, */*",
        "Authorization": "Bearer $_authToken",
        "Origin": "https://journal.top-academy.ru",
        "Referer": "https://journal.top-academy.ru/",
      };

  Future<List<HomeworkItem>> fetchAllHomeworkByStatus(int status) async {
    List<HomeworkItem> allHomeworkForStatus = [];
    int currentPage = 1;
    String? previousResponseBody;

    while (currentPage <= _maxPagesPerStatus) {
      final url = Uri.parse(
          '$_baseUrl/homework/operations/list?page=$currentPage&status=$status');
      // ignore: avoid_print
      print('Fetching homework: ${url.toString()}');
      try {
        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final currentResponseBody = response.body;

          if (currentResponseBody.isEmpty) {
            // ignore: avoid_print
            print(
                'Empty response body for status $status at page $currentPage. Breaking.');
            break;
          }

          if (previousResponseBody != null &&
              previousResponseBody == currentResponseBody) {
            // ignore: avoid_print
            print(
                'Response for page $currentPage is identical to the previous page for status $status. Assuming end of data. Breaking.');
            break;
          }

          List<dynamic> currentPageDataList;
          try {
            var decodedJson = jsonDecode(currentResponseBody);
            if (decodedJson is List) {
              currentPageDataList = decodedJson;
            } else if (decodedJson is Map &&
                decodedJson.containsKey('data') &&
                decodedJson['data'] is List) {
              currentPageDataList = decodedJson['data'];
            } else {
              // ignore: avoid_print
              print(
                  'Unexpected JSON format for homework status $status, page $currentPage. Body: $currentResponseBody');
              break;
            }
          } catch (e) {
            // ignore: avoid_print
            print(
                'Failed to decode JSON for homework status $status, page $currentPage: $e. Body: $currentResponseBody');
            break;
          }

          if (currentPageDataList.isEmpty) {
            // ignore: avoid_print
            print(
                'Empty page data list for status $status at page $currentPage. Breaking.');
            break;
          }

          for (var itemJson in currentPageDataList) {
            try {
              allHomeworkForStatus
                  .add(HomeworkItem.fromJson(itemJson as Map<String, dynamic>));
            } catch (e) {
              // ignore: avoid_print
              print("Error parsing homework item: $itemJson, error: $e");
            }
          }

          previousResponseBody = currentResponseBody;
          currentPage++;
        } else {
          // ignore: avoid_print
          print(
              'Error fetching homework for status $status, page $currentPage: ${response.statusCode} - ${response.body}');
          break;
        }
      } catch (e) {
        // ignore: avoid_print
        print(
            'Exception while fetching homework for status $status, page $currentPage: $e');
        break;
      }
    }
    if (currentPage > _maxPagesPerStatus) {
      // ignore: avoid_print
      print(
          'Reached max page limit ($_maxPagesPerStatus) for status $status. Stopping.');
    }
    return allHomeworkForStatus;
  }

  Future<List<HomeworkItem>> fetchAllHomework() async {
    List<HomeworkItem> allHomework = [];
    List<int> statusesToFetch = [0, 1, 2, 3, 5];

    for (int status in statusesToFetch) {
      try {
        final homeworkForStatus = await fetchAllHomeworkByStatus(status);
        allHomework.addAll(homeworkForStatus);
      } catch (e) {
        // ignore: avoid_print
        print('Error fetching all homework for status $status: $e');
      }
    }
    // ignore: avoid_print
    print('Total homework items fetched: ${allHomework.length}');
    return allHomework;
  }

  Future<List<LessonVisitMark>> fetchLessonVisitsAndMarks(
      {String? dateFrom, String? dateTo}) async {
    // TODO: Если API поддерживает фильтрацию по дате, добавь параметры в URL
    String urlString = '$_baseUrl/progress/operations/student-visits';
    // Пример добавления параметров (раскомментируй и адаптируй, если нужно):
    // if (dateFrom != null && dateTo != null) {
    //   urlString += '?date_from=$dateFrom&date_to=$dateTo';
    // } else if (dateFrom != null) { // Загрузка с определенной даты до текущего момента
    //    urlString += '?date_from=$dateFrom';
    // }

    final url = Uri.parse(urlString);
    // ignore: avoid_print
    print('Fetching lesson visits and marks: ${url.toString()}');

    List<LessonVisitMark> visitMarks = [];

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isNotEmpty) {
          // API возвращает список, даже если он пуст "[]"
          final List<dynamic> jsonData =
              jsonDecode(responseBody) as List<dynamic>;
          visitMarks = jsonData
              .map((item) =>
                  LessonVisitMark.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } else {
        // ignore: avoid_print
        print(
            'Error fetching lesson visits: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Exception while fetching lesson visits: $e');
    }
    // ignore: avoid_print
    print('Total lesson visits and marks fetched: ${visitMarks.length}');
    return visitMarks;
  }
}
