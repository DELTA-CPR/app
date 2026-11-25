import 'dart:io';
import 'dart:typed_data';

import 'package:app/detection/scene_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

void main() {
  test(
    'Bundled NanoDet and ArUco detect a person and a known marker together',
    () {
      final detector = SceneDetector(
        File('assets/models/nanodet.onnx').readAsBytesSync(),
      );
      final scene = cv.imread('test/fixtures/basketball.jpg');
      final marker = cv.imread('test/fixtures/aruco-4x4-50-id23.png');
      final color = cv.resize(marker, (
        96,
        96,
      ), interpolation: cv.INTER_NEAREST);
      final location = cv.Rect(270, 60, color.cols, color.rows);
      final region = scene.region(location);
      try {
        color.copyTo(region);
        final frame = detector.annotate(scene);
        expect(frame.people, hasLength(2));
        final boxes = frame.people.map((p) => p.box).toList()
          ..sort((a, b) => a.left.compareTo(b.left));
        // Normalized boxes from the upstream decoder on this exact fixture.
        expect(boxes[0].left, closeTo(0.046, 0.025));
        expect(boxes[0].top, closeTo(0.172, 0.025));
        expect(boxes[0].right, closeTo(0.253, 0.025));
        expect(boxes[0].bottom, closeTo(0.994, 0.025));
        expect(boxes[1].left, closeTo(0.677, 0.025));
        expect(boxes[1].top, closeTo(0.043, 0.025));
        expect(boxes[1].right, closeTo(1, 0.025));
        expect(boxes[1].bottom, closeTo(0.936, 0.025));
        expect(frame.markers, [23]);
        expect(frame.jpeg, isNotEmpty);

        final blank = detector.process(
          FrameInput(
            Uint8List(320 * 240 * 3 ~/ 2)
              ..fillRange(0, 320 * 240 * 3 ~/ 2, 128),
            320,
            240,
            90,
          ),
        );
        expect(blank.people, isEmpty);
        expect(blank.markers, isEmpty);
        final rotated = cv.imdecode(blank.jpeg, cv.IMREAD_COLOR);
        expect((rotated.cols, rotated.rows), (240, 320));
        rotated.dispose();
      } finally {
        region.dispose();
        location.dispose();
        color.dispose();
        marker.dispose();
        scene.dispose();
        detector.dispose();
      }
    },
  );
}
