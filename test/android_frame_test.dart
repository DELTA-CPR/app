import 'dart:typed_data';

import 'package:app/detection/android_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Packs padded Y and shared chroma planes, including a short last row',
    () {
      final chroma = Uint8List.fromList([
        21,
        11,
        22,
        12,
        99,
        99,
        23,
        13,
        24,
        14,
      ]);
      final y = Uint8List.fromList([
        1,
        2,
        3,
        4,
        99,
        99,
        5,
        6,
        7,
        8,
        99,
        99,
        9,
        10,
        11,
        12,
        99,
        99,
        13,
        14,
        15,
        16,
      ]);
      final packed = packNv21(4, 4, [
        (bytes: y, rowStride: 6, pixelStride: 1),
        (bytes: Uint8List.sublistView(chroma, 1), rowStride: 6, pixelStride: 2),
        (bytes: chroma, rowStride: 6, pixelStride: 2),
      ]);
      expect(packed, [
        ...List.generate(16, (i) => i + 1),
        21,
        11,
        22,
        12,
        23,
        13,
        24,
        14,
      ]);
    },
  );

  test('Packs planar U and V in NV21 order and rejects truncated input', () {
    final planes = [
      (bytes: Uint8List(8), rowStride: 4, pixelStride: 1),
      (bytes: Uint8List.fromList([10, 11]), rowStride: 2, pixelStride: 1),
      (bytes: Uint8List.fromList([20, 21]), rowStride: 2, pixelStride: 1),
    ];
    expect(packNv21(4, 2, planes).skip(8), [20, 10, 21, 11]);
    planes[1] = (bytes: Uint8List(1), rowStride: 2, pixelStride: 1);
    expect(() => packNv21(4, 2, planes), throwsFormatException);
  });
}
