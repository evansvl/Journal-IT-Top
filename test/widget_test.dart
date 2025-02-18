import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_it_top/main.dart'; // Убедитесь, что путь верен

void main() {
  testWidgets('Login form displays correctly', (WidgetTester tester) async {
    // Строим приложение и выполняем отрисовку.
    await tester.pumpWidget(MyApp());

    // Проверяем, что элементы формы отображаются.
    expect(find.byType(TextField), findsNWidgets(2)); // Два текстовых поля
    expect(find.byType(ElevatedButton), findsOneWidget); // Кнопка "Login"
    expect(
      find.text('Username'),
      findsOneWidget,
    ); // Текстовое поле для имени пользователя
    expect(find.text('Password'), findsOneWidget); // Текстовое поле для пароля

    // Вводим данные в текстовые поля.
    await tester.enterText(find.byType(TextField).at(0), 'Volko_fs21');
    await tester.enterText(find.byType(TextField).at(1), 'Idinahui8243A');

    // Нажимаем на кнопку входа.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Здесь можно добавить проверку, например, на успешный запрос или переход на новый экран,
    // в зависимости от того, что делает ваше приложение после нажатия кнопки входа.
    // Для примера проверим, что кнопка "Login" существует и данные были введены.
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
