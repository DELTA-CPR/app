import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

const modelSide = 416;
typedef Person = ({Rect box, double score});

class Letterbox {
  Letterbox(int width, int height)
    : width = math.max(1, width * modelSide ~/ math.max(width, height)),
      height = math.max(1, height * modelSide ~/ math.max(width, height));

  final int width, height;
  int get left => (modelSide - width) ~/ 2;
  int get top => (modelSide - height) ~/ 2;

  Rect normalize(Rect box) => Rect.fromLTRB(
    ((box.left - left) / width).clamp(0, 1),
    ((box.top - top) / height).clamp(0, 1),
    ((box.right - left) / width).clamp(0, 1),
    ((box.bottom - top) / height).clamp(0, 1),
  );
}

// Each location predicts 80 COCO scores and four 8-bin distance distributions.
Iterable<Person> decodePeople(
  Float32List scores,
  Float32List distances,
  int stride,
  Letterbox input,
) sync* {
  final side = modelSide ~/ stride;
  final cells = side * side;
  if (scores.length != cells * 80 || distances.length != cells * 32) {
    throw StateError('Unexpected NanoDet output at stride $stride.');
  }
  for (var i = 0; i < cells; i++) {
    final start = i * 80;
    final score = scores[start]; // COCO class zero is person.
    if (score < 0.35 || !score.isFinite) continue;
    var personWins = true;
    for (var c = 1; c < 80; c++) {
      if (scores[start + c] > score) {
        personWins = false;
        break;
      }
    }
    if (!personWins) continue;
    final x = (i % side) * stride + (stride - 1) / 2;
    final y = (i ~/ side) * stride + (stride - 1) / 2;
    double distance(int edge) {
      final offset = i * 32 + edge * 8;
      var peak = distances[offset];
      for (var bin = 1; bin < 8; bin++) {
        peak = math.max(peak, distances[offset + bin]);
      }
      var total = 0.0, weighted = 0.0;
      for (var bin = 0; bin < 8; bin++) {
        final weight = math.exp(distances[offset + bin] - peak);
        total += weight;
        weighted += weight * bin;
      }
      return weighted / total * stride;
    }

    final box = input.normalize(
      Rect.fromLTRB(
        x - distance(0),
        y - distance(1),
        x + distance(2),
        y + distance(3),
      ),
    );
    if (!box.isEmpty) yield (box: box, score: score);
  }
}

List<Person> suppressOverlaps(List<Person> candidates) {
  candidates.sort((a, b) => b.score.compareTo(a.score));
  final kept = <Person>[];
  for (final candidate in candidates) {
    if (kept.every((other) => _iou(candidate.box, other.box) <= 0.6)) {
      kept.add(candidate);
    }
  }
  return kept;
}

double _iou(Rect a, Rect b) {
  final overlap = a.intersect(b);
  if (overlap.isEmpty) return 0;
  final area = overlap.width * overlap.height;
  return area / (a.width * a.height + b.width * b.height - area);
}
