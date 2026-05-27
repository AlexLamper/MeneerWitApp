import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meneer_wit/data/word_repository.dart';
import 'package:meneer_wit/game/game_controller.dart';
import 'package:meneer_wit/screens/home_screen.dart';
import 'package:meneer_wit/storage/app_storage.dart';
import 'package:meneer_wit/theme.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await WordRepository.instance.load();
  final appState = await AppState.create();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider(create: (_) => GameController(appState)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows brand and main actions', (tester) async {
    await _pumpApp(tester);
    expect(find.text('Speel Nu'), findsOneWidget);
    expect(find.text('Regels'), findsOneWidget);
    expect(find.text('Uitleg'), findsOneWidget);
    expect(find.text('Ranglijst'), findsOneWidget);
  });

  testWidgets('full setup -> options -> game start flow', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Speel Nu'));
    await tester.pumpAndSettle();

    // Add three players.
    for (final name in ['Anna', 'Bram', 'Cas']) {
      await tester.enterText(find.byType(TextField).first, name);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
    }
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Spelers (3)'), findsOneWidget);

    await tester.tap(find.text('Verder'));
    await tester.pumpAndSettle();

    // Options screen with role summary + start button.
    expect(find.text('Start spel'), findsOneWidget);
    await tester.tap(find.text('Start spel'));
    await tester.pumpAndSettle();

    // Card-reveal phase: hand-off prompt for the first player.
    expect(find.textContaining('Tik om te onthullen'), findsOneWidget);
  });

  testWidgets('rules and leaderboard screens render', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Regels'));
    await tester.pumpAndSettle();
    expect(find.textContaining('misleiding en deductie'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ranglijst'));
    await tester.pumpAndSettle();
    expect(find.text('Nog geen scores.'), findsOneWidget);
  });
}
