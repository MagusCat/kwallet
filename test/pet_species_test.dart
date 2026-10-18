import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwall/core/models/pet_species.dart';
import 'package:kwall/core/widgets/pet_selection_panel.dart';

void main() {
  group('PetSpecies and Catalog Tests', () {
    test('Catalog contains all species and valid styles', () {
      final cats = PetSpeciesCatalog.forSpecies(PetSpecies.cat);
      final rats = PetSpeciesCatalog.forSpecies(PetSpecies.rat);
      final raccoons = PetSpeciesCatalog.forSpecies(PetSpecies.raccoon);

      expect(cats.length, greaterThanOrEqualTo(8));
      expect(rats.length, equals(5));
      expect(raccoons.length, equals(3));
      for (final species in PetSpecies.values) {
        expect(PetSpeciesCatalog.forSpecies(species), isNotEmpty);
      }

      // Test rat varieties
      final ratKeys = rats.map((r) => r.key).toSet();
      expect(
        ratKeys,
        containsAll([
          'rat_snow',
          'rat_hooded',
          'rat_slate',
          'rat_golden',
          'rat_ink',
        ]),
      );

      // Test raccoon varieties
      final raccoonKeys = raccoons.map((r) => r.key).toSet();
      expect(
        raccoonKeys,
        containsAll(['raccoon_classic', 'raccoon_cinnamon', 'raccoon_frost']),
      );
    });

    test('Growth stage computes scale and title correctly based on XP', () {
      expect(PetGrowthStage.fromXp(0), equals(PetGrowthStage.baby));
      expect(PetGrowthStage.fromXp(199), equals(PetGrowthStage.baby));
      expect(PetGrowthStage.fromXp(200), equals(PetGrowthStage.adult));
      expect(PetGrowthStage.fromXp(599), equals(PetGrowthStage.adult));
      expect(PetGrowthStage.fromXp(600), equals(PetGrowthStage.master));
      expect(PetGrowthStage.fromXp(1200), equals(PetGrowthStage.master));

      expect(PetGrowthStage.baby.scale, equals(0.85));
      expect(PetGrowthStage.adult.scale, equals(1.0));
      expect(PetGrowthStage.master.scale, equals(1.15));
    });

    test('Asset resolution uses baby atlas for all species under 200 XP', () {
      expect(
        PetSpeciesCatalog.resolveAsset('classic', xp: 50),
        equals('assets/pets/cat_baby.png'),
      );
      expect(
        PetSpeciesCatalog.resolveAsset('classic', xp: 250),
        equals('assets/pets/cat.png'),
      );
      expect(
        PetSpeciesCatalog.resolveAsset('rat_snow', xp: 50),
        equals('assets/pets/rat_baby.png'),
      );
      expect(
        PetSpeciesCatalog.resolveAsset('rat_snow', xp: 250),
        equals('assets/pets/rat.png'),
      );
      expect(
        PetSpeciesCatalog.resolveAsset('raccoon_classic', xp: 50),
        equals('assets/pets/raccoon_baby.png'),
      );
      expect(
        PetSpeciesCatalog.resolveAsset('raccoon_classic', xp: 250),
        equals('assets/pets/raccoon.png'),
      );
    });

    test('Random pet selection returns valid style', () {
      final randomAny = PetSpeciesCatalog.pickRandom();
      expect(PetSpeciesCatalog.styles.containsKey(randomAny.key), isTrue);

      final randomRat = PetSpeciesCatalog.pickRandom(species: PetSpecies.rat);
      expect(randomRat.species, equals(PetSpecies.rat));

      final randomRaccoon = PetSpeciesCatalog.pickRandom(
        species: PetSpecies.raccoon,
      );
      expect(randomRaccoon.species, equals(PetSpecies.raccoon));
      for (final species in PetSpecies.values) {
        expect(PetSpeciesCatalog.pickRandom(species: species).species, species);
      }
    });

    test('New companions grow into their own adult assets', () {
      for (final species in ['opossum', 'rock', 'plant']) {
        final key = '${species}_classic';
        expect(PetSpeciesCatalog.get(key).key, key);
        expect(
          PetSpeciesCatalog.resolveAsset(key, xp: 199),
          'assets/pets/${species}_baby.png',
        );
        expect(
          PetSpeciesCatalog.resolveAsset(key, xp: 200),
          'assets/pets/$species.png',
        );
        expect(
          PetSpeciesCatalog.resolveAsset(key, xp: 600),
          'assets/pets/$species.png',
        );
      }
    });
  });

  group('PetSelectionPanel Widget Tests', () {
    testWidgets('Renders species filter chips and triggers random selection', (
      tester,
    ) async {
      String selected = 'classic';
      String? suggestedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PetSelectionPanel(
              selectedStyle: selected,
              onSelectStyle: (style) => selected = style,
              onNameSuggested: (name) => suggestedName = name,
            ),
          ),
        ),
      );

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Gato'), findsOneWidget);
      expect(find.text('Rata'), findsOneWidget);
      expect(find.text('Mapache'), findsOneWidget);
      expect(find.text('Zarigüeya'), findsOneWidget);
      expect(find.text('Roca'), findsOneWidget);
      expect(find.text('Planta'), findsOneWidget);
      expect(find.text('Al azar'), findsOneWidget);

      // Tap Rat filter
      await tester.tap(find.text('Rata'));
      await tester.pump();

      expect(find.text('Remi'), findsOneWidget);
      expect(find.text('Quesito'), findsOneWidget);

      // Tap random button
      await tester.ensureVisible(find.text('Al azar'));
      await tester.tap(find.text('Al azar'));
      await tester.pump();

      expect(suggestedName, isNotNull);

      // Scrollable species filters work for the new companions too.
      for (final entry in {
        'Zarigüeya': 'Pepita',
        'Roca': 'Roco',
        'Planta': 'Brotito',
      }.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pump();
        await tester.tap(find.text(entry.value));
        await tester.pump();
        expect(suggestedName, entry.value);
        expect(PetSpeciesCatalog.get(selected).species.label, entry.key);
      }
    });
  });
}
