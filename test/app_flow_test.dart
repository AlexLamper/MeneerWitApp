import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meneer_wit/data/word_repository.dart';
import 'package:meneer_wit/game/game_controller.dart';
import 'package:meneer_wit/screens/home_screen.dart';
import 'package:meneer_wit/storage/app_storage.dart';
import 'package:meneer_wit/theme.dart';

/// Pumps a fixed number of frames instead of `pumpAndSettle`, so looping
/// animations can never stall the test.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(WordRepository.instance.load);
  final appState = await AppState.create();
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
  await _settle(tester);
}

void main() {
  testWidgets('home shows brand and main actions', (tester) async {
    await _pumpApp(tester);
    expect(find.text('Speel Nu'), findsOneWidget);
    expect(find.text('REGELS'), findsOneWidget);
    expect(find.text('UITLEG'), findsOneWidget);
    expect(find.text('RANGLIJST'), findsOneWidget);
  });

  testWidgets('setup -> name entry -> card reveal flow', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Speel Nu'));
    await _settle(tester);

    // Config screen with role rows and the start button.
    expect(find.text('Spelconfiguratie'), findsOneWidget);
    expect(find.text('Burgers'), findsOneWidget);
    await tester.tap(find.text('Start spel'));
    await _settle(tester);

    // Pass-and-play: first player enters a name.
    expect(find.text('Geef de telefoon aan'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Anna');
    await tester.tap(find.text('Bekijk kaart'));
    await _settle(tester);

    expect(find.text('Tik om te onthullen'), findsOneWidget);
    await tester.tap(find.text('Tik om te onthullen'));
    await _settle(tester);
    expect(find.text('Verberg & geef door'), findsOneWidget);

    await tester.tap(find.text('Verberg & geef door'));
    await _settle(tester);

    // Second player can't reuse Anna's name.
    await tester.enterText(find.byType(TextField), 'anna');
    await tester.tap(find.text('Bekijk kaart'));
    await _settle(tester);
    expect(find.textContaining('al gekozen'), findsOneWidget);
    expect(find.text('Tik om te onthullen'), findsNothing);
  });

  testWidgets('rules and leaderboard screens render', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('REGELS'));
    await _settle(tester);
    expect(find.textContaining('misleiding en deductie'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await _settle(tester);

    await tester.tap(find.text('RANGLIJST'));
    await _settle(tester);
    expect(find.text('Nog geen scores.'), findsOneWidget);
  });
}
