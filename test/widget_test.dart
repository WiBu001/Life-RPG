import 'package:flutter_test/flutter_test.dart';
import 'package:life_gamification/main.dart';

void main() {
  testWidgets('Life RPG loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeRPG());

    expect(find.text('Life RPG'), findsOneWidget);
    expect(find.text('ARIA'), findsOneWidget);
    expect(find.text('DAILY QUESTS'), findsOneWidget);
  });
}