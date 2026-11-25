import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import 'android_frame.dart';
import 'scene_detector.dart';
import 'worker.dart';

abstract interface class DetectionSession {
  Future<void> open(
    void Function(SceneFrame) onFrame,
    void Function(Object, StackTrace) onError,
  );
  Future<void> close();
}

int frameRotation(
  int sensorOrientation,
  int displayRotation, {
  required bool front,
}) => (sensorOrientation + (front ? displayRotation : -displayRotation)) % 360;

class CameraSession implements DetectionSession {
  static const _display = MethodChannel('app/scene_camera');
  CameraController? _camera;
  DetectorWorker? _worker;
  bool _busy = false;
  bool _closed = false;
  Timer? _watchdog;

  @override
  Future<void> open(
    void Function(SceneFrame) onFrame,
    void Function(Object, StackTrace) onError,
  ) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Open this prototype on Android.');
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw CameraException('NoCamera', 'No camera found.');
    final lens = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final camera = _camera = CameraController(
      lens,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await camera.initialize();
    final DetectorWorker worker;
    try {
      worker = _worker = await DetectorWorker.start();
    } catch (error) {
      throw CameraException(
        'DetectorStartup',
        error.toString().split('\n').first,
      );
    }
    void fail(Object error, StackTrace stack) {
      if (!_closed) onError(error, stack);
    }

    camera.addListener(() {
      if (camera.value.hasError) {
        fail(
          CameraException('CameraError', camera.value.errorDescription),
          StackTrace.current,
        );
      }
    });
    void armWatchdog() {
      _watchdog?.cancel();
      _watchdog = Timer(
        const Duration(seconds: 20),
        () => fail(
          CameraException('CameraTimeout', 'Camera stopped delivering frames.'),
          StackTrace.current,
        ),
      );
    }

    armWatchdog();
    await camera.startImageStream((image) async {
      if (_closed || _busy) return;
      _busy = true;
      try {
        // Use the display's actual rotation, including on naturally landscape devices.
        final displayRotation = await _display.invokeMethod<int>(
          'displayRotation',
        );
        if (_closed) return;
        if (displayRotation == null) {
          throw StateError('Missing display rotation.');
        }
        final rotation = frameRotation(
          lens.sensorOrientation,
          displayRotation,
          front: lens.lensDirection == CameraLensDirection.front,
        );
        final result = await worker.process(
          FrameInput(
            packNv21(image.width, image.height, [
              for (final plane in image.planes)
                (
                  bytes: plane.bytes,
                  rowStride: plane.bytesPerRow,
                  pixelStride: plane.bytesPerPixel ?? 1,
                ),
            ]),
            image.width,
            image.height,
            rotation,
          ),
        );
        if (!_closed) {
          armWatchdog();
          onFrame(result);
        }
      } catch (error, stack) {
        fail(error, stack);
      } finally {
        _busy = false;
      }
    });
  }

  @override
  Future<void> close() async {
    _closed = true;
    _watchdog?.cancel();
    _worker?.dispose();
    try {
      final camera = _camera;
      if (camera == null) return;
      try {
        if (camera.value.isStreamingImages) await camera.stopImageStream();
      } finally {
        await camera.dispose();
      }
    } catch (error, stack) {
      log(
        'Could not release camera',
        name: 'detector',
        error: error,
        stackTrace: stack,
      );
    }
  }
}
