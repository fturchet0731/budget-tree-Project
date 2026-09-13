// Renders the app launcher icon to assets/icon/app_icon.png at 1024x1024.
//
// The mark is the **Ancient** status tree (assets/status_trees/ancient.png,
// first frame) drawn crisp (nearest-neighbour) on the brand tint, so the app
// icon matches the launch-screen hero.
//
// Run:  flutter test tool/gen_app_icon.dart
// Then: dart run flutter_launcher_icons   (regenerates every platform icon)
//
// It lives under tool/ (not test/) so the normal `flutter test` run never
// rewrites the asset; invoke it explicitly when the logo art changes.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate app_icon.png from the Ancient status tree', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    const px = 1024.0;
    // Matches adaptive_icon_background in pubspec so the tree sits on the same
    // tint whether or not the platform applies an adaptive mask.
    const bg = Color(0xFFF6FCE9);

    final data = await rootBundle.load('assets/status_trees/ancient.png');
    final sprite = await decodeImageFromList(data.buffer.asUint8List());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, px, px));
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, px, px), Paint()..color = bg);

    // First of the four frames; frames are square cells.
    final frameW = sprite.width / 4;
    final frameH = sprite.height.toDouble();
    final src = Rect.fromLTWH(0, 0, frameW, frameH);

    // Keep the tree inside the central ~62% so it survives the adaptive-icon
    // safe-zone mask, nudged up a touch so the canopy is centred.
    const side = px * 0.62;
    final dst = Rect.fromLTWH((px - side) / 2, (px - side) / 2 - px * 0.02,
        side, side);
    canvas.drawImageRect(
      sprite,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(px.toInt(), px.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final dir = Directory('assets/icon');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('assets/icon/app_icon.png');
    file.writeAsBytesSync(bytes!.buffer.asUint8List());

    // ignore: avoid_print
    print('Wrote ${file.path} (${bytes.lengthInBytes} bytes)');
    expect(file.existsSync(), isTrue);
  });
}
