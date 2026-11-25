import 'dart:async';
import 'dart:io';

import 'package:app/detection/camera_session.dart';
import 'package:app/detection/scene_detector.dart';
import 'package:app/main.dart';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSession implements DetectionSession {
  final opening = Completer<void>();
  bool closed = false;
  late void Function(SceneFrame) emit;
  @override
  Future<void> open(
    void Function(SceneFrame) onFrame,
    void Function(Object, StackTrace) onError,
  ) {
    emit = onFrame;
    return opening.future;
  }

  @override
  Future<void> close() async => closed = true;
}

void main() {
  testWidgets('Camera permission error can be retried and startup cancelled', (
    tester,
  ) async {
    final sessions = <FakeSession>[];
    await tester.pumpWidget(
      DetectorApp(
        createSession: () {
          final session = FakeSession();
          sessions.add(session);
          return session;
        },
      ),
    );
    await tester.tap(find.text('Start camera'));
    await tester.pump();
    expect(find.text('Starting camera'), findsOneWidget);
    sessions.single.opening.completeError(
      CameraException('CameraAccessDenied', 'Denied'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Allow camera access'), findsOneWidget);
    expect(sessions.single.closed, isTrue);
    await tester.tap(find.text('Retry camera'));
    await tester.pump();
    await tester.tap(find.text('Stop camera'));
    sessions.last.opening.complete();
    await tester.pumpAndSettle();
    expect(sessions.last.closed, isTrue);
    expect(find.text('Start camera'), findsOneWidget);
  });
  testWidgets('Shows the native camera error and code when startup fails', (
    tester,
  ) async {
    final session = FakeSession();
    await tester.pumpWidget(DetectorApp(createSession: () => session));
    await tester.tap(find.text('Start camera'));
    await tester.pump();
    session.opening.completeError(
      CameraException('CameraError', 'Camera is in use'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Camera unavailable'), findsOneWidget);
    expect(
      find.textContaining('Camera is in use (CameraError)'),
      findsOneWidget,
    );
    expect(find.text('Retry camera'), findsOneWidget);
  });
  testWidgets('A stopped session cannot publish over a resumed camera', (
    tester,
  ) async {
    final sessions = <FakeSession>[];
    final jpeg = File('test/fixtures/basketball.jpg').readAsBytesSync();
    await tester.pumpWidget(
      DetectorApp(
        createSession: () {
          final session = FakeSession();
          sessions.add(session);
          return session;
        },
      ),
    );
    await tester.tap(find.text('Start camera'));
    await tester.pump();
    final first = sessions.single;
    first.opening.complete();
    first.emit(SceneFrame(jpeg, [], [23]));
    await tester.pump();
    expect(find.text('People 0   ·   ArUco markers 1'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(first.closed, isTrue);
    expect(sessions, hasLength(2));
    first.emit(SceneFrame(jpeg, [], [23]));
    await tester.pump();
    expect(find.text('Starting camera'), findsOneWidget);
    sessions.last.opening.complete();
    sessions.last.emit(SceneFrame(jpeg, [], []));
    await tester.pump();
    expect(find.text('People 0   ·   ArUco markers 0'), findsOneWidget);
    await tester.tap(find.text('Stop camera'));
    await tester.pump();
    expect(sessions.last.closed, isTrue);
  });
}
