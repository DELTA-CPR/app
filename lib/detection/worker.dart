import 'dart:isolate';

import 'package:flutter/services.dart';

import 'scene_detector.dart';

class DetectorWorker {
  DetectorWorker._(this._port);
  final SendPort _port;

  static Future<DetectorWorker> start() async {
    final data = await rootBundle.load('assets/models/nanodet.onnx');
    final ready = ReceivePort();
    final isolate = await Isolate.spawn(_run, (
      ready.sendPort,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    ));
    try {
      final port = await ready.first.timeout(const Duration(seconds: 30));
      if (port is! SendPort) throw StateError('$port');
      return DetectorWorker._(port);
    } catch (_) {
      isolate.kill(priority: Isolate.immediate);
      rethrow;
    } finally {
      ready.close();
    }
  }

  Future<SceneFrame> process(FrameInput input) async {
    final reply = ReceivePort();
    try {
      _port.send((reply.sendPort, input));
      final result = await reply.first.timeout(const Duration(seconds: 15));
      if (result is! SceneFrame) throw StateError('$result');
      return result;
    } finally {
      reply.close();
    }
  }

  void dispose() => _port.send(null);

  static Future<void> _run((SendPort, Uint8List) init) async {
    final requests = ReceivePort();
    SceneDetector? detector;
    try {
      detector = SceneDetector(init.$2);
      init.$1.send(requests.sendPort);
      await for (final request in requests) {
        if (request == null) break;
        final (reply, input) = request as (SendPort, FrameInput);
        try {
          reply.send(detector.process(input));
        } catch (error, stack) {
          reply.send('$error\n$stack');
        }
      }
    } catch (error, stack) {
      init.$1.send('$error\n$stack');
    } finally {
      requests.close();
      detector?.dispose();
    }
  }
}
