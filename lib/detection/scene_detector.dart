import 'dart:typed_data';

import 'package:opencv_dart/opencv_dart.dart' as cv;

import 'nanodet.dart';

class FrameInput {
  FrameInput(this.bytes, this.width, this.height, this.rotation);
  final Uint8List bytes;
  final int width, height, rotation;
}

class SceneFrame {
  SceneFrame(this.jpeg, this.people, this.markers);
  final Uint8List jpeg;
  final List<Person> people;
  final List<int> markers;
}

class SceneDetector {
  SceneDetector(Uint8List model) : _net = cv.Net.fromOnnxBytes(model);

  final cv.Net _net;
  // Paired classification and distance heads in the bundled ONNX graph.
  // OpenCV graph engines can enumerate unconnected outputs in different orders.
  static const _outputs = ['792', '795', '814', '817', '836', '839'];
  final _dictionary = cv.ArucoDictionary.predefined(
    cv.PredefinedDictionaryType.DICT_4X4_50,
  );
  final _parameters = cv.ArucoDetectorParameters.empty();
  late final _aruco = cv.ArucoDetector.create(_dictionary, _parameters);
  final _mean = cv.Mat.fromList(4, 1, cv.MatType.CV_64FC1, [
    103.53,
    116.28,
    123.675,
    0.0,
  ]);
  final _std = cv.Mat.fromList(4, 1, cv.MatType.CV_64FC1, [
    57.375,
    57.12,
    58.395,
    1.0,
  ]);
  final _personColor = cv.Scalar(80, 250, 160);
  final _markerColor = cv.Scalar(255, 210, 80);

  SceneFrame process(FrameInput input) {
    if (input.width.isOdd ||
        input.height.isOdd ||
        input.width <= 0 ||
        input.height <= 0 ||
        input.bytes.length != input.width * input.height * 3 ~/ 2) {
      throw FormatException('Invalid packed NV21 camera frame.');
    }
    final yuv = cv.Mat.zeros(
      input.height * 3 ~/ 2,
      input.width,
      cv.MatType.CV_8UC1,
    );
    try {
      yuv.data.setAll(0, input.bytes);
      final bgr = cv.cvtColor(yuv, cv.COLOR_YUV2BGR_NV21);
      try {
        if (input.rotation == 0) return annotate(bgr);
        final upright = cv.rotate(bgr, switch (input.rotation) {
          90 => cv.ROTATE_90_CLOCKWISE,
          180 => cv.ROTATE_180,
          270 => cv.ROTATE_90_COUNTERCLOCKWISE,
          _ => throw ArgumentError.value(input.rotation),
        });
        try {
          return annotate(upright);
        } finally {
          upright.dispose();
        }
      } finally {
        bgr.dispose();
      }
    } finally {
      yuv.dispose();
    }
  }

  // Draw on the exact inference frame so movement or display scaling cannot
  // separate the overlays from the people and markers they describe.
  SceneFrame annotate(cv.Mat bgr) {
    final people = _people(bgr);
    final (corners, ids, rejected) = _aruco.detectMarkers(bgr);
    try {
      final markers = ids.toList();
      if (markers.isNotEmpty) {
        cv.arucoDrawDetectedMarkers(bgr, corners, ids, _markerColor);
      }
      for (final person in people) {
        final box = person.box;
        final left = (box.left * bgr.cols).floor();
        final top = (box.top * bgr.rows).floor();
        final rect = cv.Rect(
          left,
          top,
          (box.right * bgr.cols).ceil() - left,
          (box.bottom * bgr.rows).ceil() - top,
        );
        final origin = cv.Point(left, (top - 5).clamp(16, bgr.rows));
        try {
          cv.rectangle(bgr, rect, _personColor, thickness: 2);
          cv.putText(
            bgr,
            'Person ${(person.score * 100).round()}%',
            origin,
            cv.FONT_HERSHEY_SIMPLEX,
            0.5,
            _personColor,
            thickness: 2,
          );
        } finally {
          rect.dispose();
          origin.dispose();
        }
      }
      final (ok, jpeg) = cv.imencode('.jpg', bgr);
      if (!ok) throw StateError('Could not display camera frame.');
      return SceneFrame(jpeg, people, markers);
    } finally {
      corners.dispose();
      ids.dispose();
      rejected.dispose();
    }
  }

  List<Person> _people(cv.Mat bgr) {
    final input = Letterbox(bgr.cols, bgr.rows);
    final mats = <cv.Mat>[];
    cv.Mat own(cv.Mat mat) {
      mats.add(mat);
      return mat;
    }

    try {
      final small = own(
        cv.resize(bgr, (
          input.width,
          input.height,
        ), interpolation: cv.INTER_AREA),
      );
      final rgb = own(cv.cvtColor(small, cv.COLOR_BGR2RGB));
      final padded = own(
        cv.copyMakeBorder(
          rgb,
          input.top,
          modelSide - input.height - input.top,
          input.left,
          modelSide - input.width - input.left,
          cv.BORDER_CONSTANT,
        ),
      );
      final normalized = own(
        cv.subtract(padded, _mean, dtype: cv.MatType.CV_32F),
      );
      cv.divide(normalized, _std, dst: normalized);
      final blob = own(cv.blobFromImage(normalized));
      _net.setInput(blob);
      final results = _net.forwardLayers(_outputs);
      try {
        final candidates = <Person>[];
        const strides = [8, 16, 32];
        if (results.length != strides.length * 2) {
          throw StateError('Unexpected NanoDet heads.');
        }
        for (final (i, stride) in strides.indexed) {
          final scores = own(results[i * 2]);
          final distances = own(results[i * 2 + 1]);
          candidates.addAll(
            decodePeople(
              Float32List.sublistView(scores.data),
              Float32List.sublistView(distances.data),
              stride,
              input,
            ),
          );
        }
        return suppressOverlaps(candidates);
      } finally {
        results.dispose();
      }
    } finally {
      for (final mat in mats.reversed) {
        mat.dispose();
      }
    }
  }

  void dispose() {
    _aruco.dispose();
    _parameters.dispose();
    _dictionary.dispose();
    _net.dispose();
    _mean.dispose();
    _std.dispose();
    _personColor.dispose();
    _markerColor.dispose();
  }
}
