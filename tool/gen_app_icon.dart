// Renders the AppLogo mark to assets/icon/app_icon.png at 1024x1024.
//
// Run:  flutter test tool/gen_app_icon.dart
// Then: dart run flutter_launcher_icons   (regenerates every platform icon)
//
// It lives under tool/ (not test/) so the normal `flutter test` run never
// rewrites the asset; invoke it explicitly when the logo art changes.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/widgets/app_logo.dart';

void main() {
  test('generate app_icon.png from AppLogoPainter', () async {
    const px = 1024.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, px, px),
    );

    const AppLogoPainter().paint(canvas, const Size(px, px));

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
