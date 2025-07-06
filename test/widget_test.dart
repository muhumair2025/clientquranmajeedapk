// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:quran_majeed/main.dart';
import 'package:quran_majeed/providers/theme_provider.dart';

void main() {
  testWidgets('Quran Majeed app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const QuranMajeedApp(),
      ),
    );

    // Verify that our app has the title
    expect(find.text('قرآن مجید'), findsOneWidget);
    
    // Verify that main cards are present
    expect(find.text('عقیده'), findsOneWidget);
    expect(find.text('تفسیر او ترجمه'), findsOneWidget);
  });
}
