import 'dart:typed_data';

/// Android YUV_420_888 planes can have row padding and interleaved chroma.
typedef YuvPlane = ({Uint8List bytes, int rowStride, int pixelStride});

Uint8List packNv21(int width, int height, List<YuvPlane> planes) {
  if (width <= 0 ||
      height <= 0 ||
      width.isOdd ||
      height.isOdd ||
      planes.length != 3) {
    throw FormatException(
      'Expected three YUV planes for a $width×$height frame, received ${planes.length}.',
    );
  }
  final lumaSize = width * height;
  final packed = Uint8List(lumaSize + lumaSize ~/ 2);

  void copyPlane(YuvPlane plane, int cols, int rows, int start, int step) {
    final rowBytes = (cols - 1) * plane.pixelStride + 1;
    if (plane.pixelStride < 1 ||
        plane.rowStride < rowBytes ||
        plane.bytes.length < (rows - 1) * plane.rowStride + rowBytes) {
      throw FormatException(
        'Camera plane is too short or has invalid strides '
        '(${plane.bytes.length} bytes, row ${plane.rowStride}, pixel ${plane.pixelStride}).',
      );
    }
    if (step == 1 && plane.pixelStride == 1 && plane.rowStride == cols) {
      packed.setRange(start, start + rows * cols, plane.bytes);
      return;
    }
    var out = start;
    for (var row = 0; row < rows; row++) {
      var src = row * plane.rowStride;
      if (step == 1 && plane.pixelStride == 1) {
        packed.setRange(out, out + cols, plane.bytes, src);
        out += cols;
      } else {
        for (var col = 0; col < cols; col++) {
          packed[out] = plane.bytes[src];
          out += step;
          src += plane.pixelStride;
        }
      }
    }
  }

  copyPlane(planes[0], width, height, 0, 1);
  copyPlane(planes[2], width ~/ 2, height ~/ 2, lumaSize, 2);
  copyPlane(planes[1], width ~/ 2, height ~/ 2, lumaSize + 1, 2);
  return packed;
}
