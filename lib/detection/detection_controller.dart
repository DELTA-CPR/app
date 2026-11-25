import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

import 'camera_session.dart';
import 'scene_detector.dart';

enum DetectionPhase { idle, starting, live, error }

class DetectionController extends ChangeNotifier {
  DetectionController(this._createSession);
  final DetectionSession Function() _createSession;
  DetectionPhase phase = DetectionPhase.idle;
  SceneFrame? frame;
  String? errorMessage;
  String errorTitle = 'Detection unavailable';
  DetectionSession? _session;
  Future<void> _pending = Future.value();
  int _generation = 0;
  bool _wanted = false;

  void start() {
    if (phase == DetectionPhase.live || phase == DetectionPhase.starting) {
      return;
    }
    _wanted = true;
    final generation = ++_generation;
    phase = DetectionPhase.starting;
    errorMessage = null;
    notifyListeners();
    _pending = _pending.then((_) async {
      if (generation != _generation) return;
      final session = _session = _createSession();
      try {
        await session.open((result) {
          if (generation != _generation) return;
          frame = result;
          phase = DetectionPhase.live;
          notifyListeners();
        }, (error, stack) => _fail(generation, error, stack));
      } catch (error, stack) {
        _fail(generation, error, stack);
      }
    });
  }

  void _fail(int generation, Object error, StackTrace stack) {
    if (generation != _generation) return;
    log(
      'Camera detection failed',
      name: 'detector',
      error: error,
      stackTrace: stack,
    );
    _wanted = false;
    _release();
    errorTitle = switch (error) {
      CameraException(code: 'DetectorStartup') => 'Detector could not load',
      CameraException() => 'Camera unavailable',
      _ => 'Detection unavailable',
    };
    errorMessage = switch (error) {
      CameraException(
        code: 'CameraAccessDenied' || 'CameraAccessDeniedWithoutPrompt',
      ) =>
        'Allow camera access in Android settings, then retry.',
      UnsupportedError() => 'Open this prototype on Android.',
      CameraException(code: 'NoCamera') =>
        'Connect an Android camera, then retry.',
      CameraException(:final code, :final description) =>
        '${description?.trim().isNotEmpty == true ? description : 'Camera startup failed.'} ($code)\nRetry camera to try again.',
      _ =>
        'Frame detection failed. ${error.toString().split('\n').first}\nRetry camera to reload the detector.',
    };
    phase = DetectionPhase.error;
    notifyListeners();
  }

  void stop({bool suspend = false}) {
    if (!suspend) _wanted = false;
    if (phase == DetectionPhase.idle || (suspend && !_wanted)) return;
    _release();
    phase = DetectionPhase.idle;
    notifyListeners();
  }

  void resume() {
    if (_wanted && phase == DetectionPhase.idle) start();
  }

  void _release() {
    _generation++;
    frame = null;
    final session = _session;
    _session = null;
    _pending = _pending.then((_) async => session?.close());
  }

  @override
  void dispose() {
    _wanted = false;
    _release();
    super.dispose();
  }
}
