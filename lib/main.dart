import 'package:material_ui/material_ui.dart';

import 'detection/camera_session.dart';
import 'detection/detection_controller.dart';

void main() => runApp(const DetectorApp());

class DetectorApp extends StatelessWidget {
  const DetectorApp({super.key, this.createSession = CameraSession.new});
  final DetectionSession Function() createSession;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Scene detector',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff52dba0),
        brightness: Brightness.dark,
      ),
    ),
    home: DetectorScreen(createSession: createSession),
  );
}

class DetectorScreen extends StatefulWidget {
  const DetectorScreen({super.key, required this.createSession});
  final DetectionSession Function() createSession;
  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen>
    with WidgetsBindingObserver {
  late final DetectionController controller;

  @override
  void initState() {
    super.initState();
    controller = DetectionController(widget.createSession);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      controller.stop(suspend: true);
    } else if (state == AppLifecycleState.resumed) {
      controller.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scene detector')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final phase = controller.phase;
          final frame = controller.frame;
          final running =
              phase == DetectionPhase.live || phase == DetectionPhase.starting;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: frame == null
                          ? _CameraStatus(
                              phase: phase,
                              message: controller.errorMessage,
                              errorTitle: controller.errorTitle,
                            )
                          : Image.memory(
                              frame.jpeg,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              semanticLabel: 'Camera frame with person boxes and ArUco marker outlines',
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (frame != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'People ${frame.people.length}   ·   ArUco markers ${frame.markers.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                if (running)
                  OutlinedButton.icon(
                    onPressed: controller.stop,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stop camera'),
                  )
                else
                  FilledButton.icon(
                    onPressed: controller.start,
                    icon: const Icon(Icons.videocam_outlined),
                    label: Text(
                      phase == DetectionPhase.error
                          ? 'Retry camera'
                          : 'Start camera',
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _CameraStatus extends StatelessWidget {
  const _CameraStatus({
    required this.phase,
    required this.message,
    required this.errorTitle,
  });
  final DetectionPhase phase;
  final String? message;
  final String errorTitle;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (phase) {
      DetectionPhase.error => (
        errorTitle,
        message ?? 'Try opening the camera again.',
      ),
      DetectionPhase.starting => (
        'Starting camera',
        'Preparing the on-device detector…',
      ),
      _ => (
        'Camera ready',
        'Detect people and 4×4 ArUco markers (DICT_4X4_50) on this device.',
      ),
    };
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phase == DetectionPhase.starting)
              const CircularProgressIndicator()
            else
              Icon(
                phase == DetectionPhase.error
                    ? Icons.videocam_off_outlined
                    : Icons.center_focus_strong,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
