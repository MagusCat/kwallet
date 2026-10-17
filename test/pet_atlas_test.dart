import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = [
    'cat_baby.png',
    'rat.png',
    'rat_baby.png',
    'raccoon.png',
    'raccoon_baby.png',
    'opossum.png',
    'opossum_baby.png',
    'rock.png',
    'rock_baby.png',
    'plant.png',
    'plant_baby.png',
  ];
  for (final asset in assets) {
    test('$asset has complete frames with clean transparency', () async {
      final codec = await ui.instantiateImageCodec(
        await File(asset).readAsBytes(),
      );
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      try {
        expect(image.width, 256);
        expect(image.height, 320);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final signatures = <int, Set<String>>{};
        final opaqueColors = <int>{};
        for (var row = 0; row < 10; row++) {
          signatures[row] = {};
          for (var frame = 0; frame < 8; frame++) {
            final signature = StringBuffer();
            var visible = 0;
            for (var y = 0; y < 32; y++) {
              for (var x = 0; x < 32; x++) {
                final offset = ((row * 32 + y) * 256 + frame * 32 + x) * 4;
                final alpha = data.getUint8(offset + 3);
                expect(alpha, anyOf(0, 255), reason: '$asset has a soft pixel');
                if (alpha == 0) {
                  signature.write('.');
                  continue;
                }
                visible++;
                // A two-pixel clear gutter prevents clipping and neighboring-frame bleed.
                expect(
                  x,
                  inInclusiveRange(2, 29),
                  reason: '$asset row $row frame $frame',
                );
                expect(
                  y,
                  inInclusiveRange(2, 29),
                  reason: '$asset row $row frame $frame',
                );
                final color =
                    data.getUint8(offset) << 16 |
                    data.getUint8(offset + 1) << 8 |
                    data.getUint8(offset + 2);
                opaqueColors.add(color);
                signature.write(color.toRadixString(16));
              }
            }
            expect(
              visible,
              greaterThan(15),
              reason: '$asset row $row frame $frame is empty',
            );
            signatures[row]!.add(signature.toString());
          }
        }
        for (final row in [4, 5, 7, 8, 9]) {
          expect(
            signatures[row]!.length,
            greaterThan(2),
            reason: '$asset row $row needs different poses',
          );
        }
        expect(
          opaqueColors.length,
          lessThanOrEqualTo(8),
          reason: '$asset should use flat colors without noisy gradients',
        );
      } finally {
        image.dispose();
      }
    });
  }

  test('species and growth stages use distinct artwork', () async {
    final files = ['cat.png', ...assets];
    final contents = await Future.wait(
      files.map((asset) => File(asset).readAsBytes()),
    );
    for (var i = 0; i < contents.length; i++) {
      for (var j = i + 1; j < contents.length; j++) {
        expect(
          contents[i],
          isNot(orderedEquals(contents[j])),
          reason: '${files[i]} and ${files[j]} must differ',
        );
      }
    }
  });
}
