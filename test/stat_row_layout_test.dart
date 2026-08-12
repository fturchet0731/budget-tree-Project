// Unbounded-height guard for the stat rows.
//
// The profile's TREES / STREAK / SAVED blocks and the budget tree's
// INCOME / ALLOCATED / LEFT strip both use a Row with
// CrossAxisAlignment.stretch so the cards share one height. Stretch needs a
// **bounded** height, but both rows sit somewhere that offers unbounded
// height — a SliverToBoxAdapter on the profile, a PixelBox (which sizes to
// its child) on the budget tree. Without an IntrinsicHeight the row throws on
// every frame and the whole screen renders blank.
//
// This reproduces the exact shape: a stretch Row of Expanded cards inside a
// SliverToBoxAdapter. Delete the IntrinsicHeight and this test fails.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/theme/app_dims.dart';
import 'package:budget_app_project/widgets/pixel/pixel.dart';

Widget statRow() {
  Widget block(String label, String value) => Expanded(
        child: PixelBox(
          padding: const EdgeInsets.all(9),
          drop: AppDims.dropButton,
          child: Column(
            children: [
              Text(label),
              const SizedBox(height: 5),
              Text(value),
            ],
          ),
        ),
      );

  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        block('TREES', '4'),
        const SizedBox(width: AppDims.s8),
        block('STREAK', '5'),
        const SizedBox(width: AppDims.s8),
        block('SAVED', r'$3.1k'),
      ],
    ),
  );
}

void main() {
  testWidgets('stretch stat row survives unbounded height in a sliver',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(14),
                sliver: SliverToBoxAdapter(child: statRow()),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // All three cards ended up the same height, which is the point of stretch.
    final boxes = tester.widgetList(find.byType(PixelBox)).length;
    expect(boxes, 3);
    final heights = tester
        .renderObjectList<RenderBox>(find.byType(PixelBox))
        .map((b) => b.size.height)
        .toSet();
    expect(heights.length, 1, reason: 'stat cards should share one height');
  });
}
