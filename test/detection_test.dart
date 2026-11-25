import 'dart:typed_data';

import 'package:app/detection/camera_session.dart';
import 'package:app/detection/nanodet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Letterboxing maps landscape and portrait bounds back to their image',
    () {
      expect(
        Letterbox(640, 480).normalize(const Rect.fromLTRB(0, 52, 416, 364)),
        const Rect.fromLTRB(0, 0, 1, 1),
      );
      expect(
        Letterbox(480, 640).normalize(const Rect.fromLTRB(52, 0, 364, 416)),
        const Rect.fromLTRB(0, 0, 1, 1),
      );
    },
  );

  test('Person class, distribution distances and overlap suppression', () {
    const stride = 32, cells = 13 * 13, center = 6 * 13 + 6;
    final scores = Float32List(cells * 80);
    final distances = Float32List(cells * 32);
    scores[center * 80] = 0.9;
    scores[80] = 0.5;
    scores[81] = 0.8;
    final person = decodePeople(
      scores,
      distances,
      stride,
      Letterbox(416, 416),
    ).single;
    expect(person.box.left, closeTo((207.5 - 112) / 416, 0.00001));
    expect(suppressOverlaps([person, (score: 0.7, box: person.box)]), [person]);
  });

  test('Android rotation follows lens and device orientation', () {
    expect(frameRotation(90, 90, front: false), 0);
    expect(frameRotation(90, 0, front: false), 90);
    expect(frameRotation(270, 270, front: true), 180);
  });
}
