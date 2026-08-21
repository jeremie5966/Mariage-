import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app.dart';

void main() {
  testWidgets('affiche l’accueil du mariage', (tester) async {
    await tester.pumpWidget(const MariageApp());

    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.byType(Image), findsAtLeastNWidgets(5));
    expect(find.text('Votre mariage'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
