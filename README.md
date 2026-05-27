# Meneer Wit

De gratis Nederlandse versie van **Undercover / Mister White** — nu als mobiele app.

Meneer Wit is een party-spel van misleiding en deductie dat je lokaal (pass-and-play)
op één telefoon speelt met 3 tot 10 spelers. Geen account, geen advertenties, geen
betalingen — gewoon spelen. Dit is de native Flutter-app, gebaseerd op
[www.meneerwit.com](https://www.meneerwit.com).

## Spelregels

Er zijn drie rollen:

- **Burger** — krijgt het geheime woord en moet de indringers vinden.
- **Undercover** — krijgt een woord dat lijkt op dat van de Burgers en moet onopgemerkt blijven.
- **Mister White** — krijgt geen woord en moet het geheime woord raden door goed te luisteren.

Elke ronde geeft iedereen om de beurt één hint over zijn woord. Daarna stemt de groep
wie eruit moet. Wie wint?

- **Burgers** winnen als alle Undercovers én Mister Whites zijn uitgeschakeld.
- **Infiltranten** winnen zodra er nog maar één Burger over is.
- **Mister White** wint direct als hij na ontmaskering het woord van de Burgers raadt.

## Functies

- 1600+ Nederlandse woordparen, verdeeld over 24 categorieën
- Instelbaar aantal Undercovers en Mister Whites
- Optionele hint voor Mister White (toont de categorie)
- Eigen woorden gebruiken
- Lokale ranglijst met scores per speler
- Licht / donker / systeem thema
- Volledig offline — geen internet, account of betaling nodig

## Tech

- **Flutter** (Dart) — Android & iOS
- `provider` voor state management
- `shared_preferences` voor de ranglijst en instellingen
- `confetti` voor het winscherm

## Aan de slag

```bash
flutter pub get
flutter run
```

### Tests

```bash
flutter test
```

### Release (Android)

```bash
flutter build appbundle --release
```

De woordenlijst staat in `assets/words.json`. De spel-logica zit in
`lib/game/game_controller.dart` en de schermen in `lib/screens/`.

## Credits

Gemaakt door **Alex Lamper**. Gebaseerd op het originele webspel
[meneerwit.com](https://www.meneerwit.com). Lettertype: Geist (OFL).
