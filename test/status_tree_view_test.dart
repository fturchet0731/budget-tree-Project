// Guards that every one of the sixteen status-tree sprites is actually bundled
// and decodes to a well-formed four-frame sheet. A missing or misnamed asset
// degrades to an empty box at runtime rather than throwing, so without this a
// dropped or renamed sprite would pass silently.

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/services/tree_health_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final keys = <String>[
    ...TreeHealthTier.values.map((t) => t.name),
    ...PrestigeTier.values.map((t) => t.name),
  ];

  test('there are sixteen tiers, matching the sprite set', () {
    expect(keys.length, 16);
    expect(keys.toSet().length, 16, reason: 'tier names must be unique');
  });

  testWidgets('every tier sprite is bundled and decodes to four frames',
      (tester) async {
    // Image decoding runs on the real engine, so it needs the true event loop.
    await tester.runAsync(() async {
      for (final key in keys) {
        final path = 'assets/status_trees/$key.png';
        final data = await rootBundle.load(path);
        final image = await decodeImageFromList(data.buffer.asUint8List());

        // A horizontal four-frame sheet of square cells.
        expect(image.width % 4, 0, reason: '$path width not divisible by 4');
        expect(image.width ~/ 4, image.height,
            reason: '$path frames are not square');
      }
    });
  });
}
