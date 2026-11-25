# Scene detector for Android

Tap **Start camera** and grant camera access. Each analyzed frame shows a box and confidence score for each detected person. ArUco markers show their four corners and numeric IDs. Use markers from the **DICT_4X4_50** dictionary (IDs 0–49) with a white margin. Open or print the [sample marker, ID 23](test/fixtures/aruco-4x4-50-id23.png) to try it.

The app prefers the rear camera. It reads the Android YUV planes using their row and pixel strides, packs them as NV21, and processes one frame at a time in a worker isolate and skips incoming frames while inference is busy. OpenCV draws on the same upright image used for inference, so overlays stay aligned when the phone or subject moves. Frames stay in memory. Both detectors work offline from the first launch.

## Local detector choice

| Option | Fit for this prototype |
| --- | --- |
| [OpenCV Zoo NanoDet](https://github.com/opencv/opencv_zoo/tree/48b10fa505aeb51fbd127fc60a5c660040e823b7/models/object_detection_nanodet) | Selected. The 3.8 MB FP32 ONNX model runs in the same OpenCV runtime as ArUco and produces multiple COCO object boxes. The app retains the person class, uses 416 × 416 letterboxed RGB input, a 0.35 score threshold and 0.60 IoU suppression. |
| [EfficientDet-Lite0](https://ai.google.dev/edge/mediapipe/solutions/vision/object_detector#models) | A mobile object detector with 320 × 320 input and a quantized model option. A candidate for a device benchmark if a LiteRT implementation is considered. |
| [MediaPipe Pose person detector](https://github.com/opencv/opencv_zoo/tree/48b10fa505aeb51fbd127fc60a5c660040e823b7/models/person_detection_mediapipe) | Designed to initialize a pose pipeline with body alignment keypoints. NanoDet directly supplies the visible person boxes needed here. |

The app bundles the [upstream NanoDet weights](https://github.com/opencv/opencv_zoo/blob/48b10fa505aeb51fbd127fc60a5c660040e823b7/models/object_detection_nanodet/object_detection_nanodet_2022nov.onnx) and upstream Apache 2.0 license under `assets/models/`. The ONNX file is 3,800,954 bytes with SHA-256 `4b82da9944b88577175ee23a459dce2e26e6e4be573def65b1055dc2d9720186`. ArUco uses OpenCV’s predefined dictionary. [OpenCV marker guide](https://docs.opencv.org/4.x/d5/dae/tutorial_aruco_detection.html)

## Run and verify

From the Flutter app directory, use a Flutter SDK satisfying the package constraints, an Android SDK/NDK, and CMake and Ninja on your PATH. The first native build downloads OpenCV sources and compiles them for the target architecture. [OpenCV Dart build instructions](https://pub.dev/packages/opencv_dart)

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <android-device-id>
```

The native test uses a JPEG conversion of the [OpenCV basketball sample](https://github.com/opencv/opencv/blob/4.12.0/samples/data/basketball1.png) and inserts a known marker into the image. It exercises the bundled weights, ArUco decoding, and a blank rotated NV21 frame. To check a handset, point it at a person beside a marker, rotate the phone, then move both out of view. The counts and overlays should update together.
