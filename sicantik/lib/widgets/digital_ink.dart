import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart' hide Ink;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sicantik/internationalization.dart';
import 'package:sicantik/utils.dart';

class DigitalInkView extends StatefulWidget {
  String filePath;

  DigitalInkView({Key? key, required this.filePath}) : super(key: key);

  @override
  _DigitalInkViewState createState() => _DigitalInkViewState();
}

class _DigitalInkViewState extends State<DigitalInkView> {
  final Ink _ink = Ink();
  List<StrokePoint> _points = [];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          final commonStorage = GetStorage();
          String selectedLanguageCode =
              commonStorage.read("inkRecognitionLanguage") ?? "en";

          List<String> detectedWord = ["none"];
          commonStorage.writeInMemory(
              "detectedWord_temp", detectedWord);
          await Alert(
              context: context,
              content: Flex(
                direction: Axis.vertical,
                children: [
                  const Text(
                    'Ink recognition language:',
                    style: TextStyle(fontSize: 14),
                  ),
                  StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                    return DropdownButton<String>(
                      isExpanded: true,
                      onChanged: (selectedVal) async {
                        setState(() {
                          selectedLanguageCode = selectedVal ?? "en";
                        });
                      },
                      value: selectedLanguageCode,
                      items: supportedInkRecognitionLanguage.entries
                          .map(
                            (mapEntry) => DropdownMenuItem(
                              value: mapEntry.key,
                              child: Text(mapEntry.value,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                    );
                  })
                ],
              ),
              buttons: [
                DialogButton(
                    child: const Text("OK"),
                    onPressed: () async {
                      await commonStorage.write(
                          "inkRecognitionLanguage", selectedLanguageCode);

                      final DigitalInkRecognizerModelManager modelManager =
                          DigitalInkRecognizerModelManager();

                      bool downloaded = await modelManager
                          .isModelDownloaded(selectedLanguageCode);
                      if (!downloaded) {
                        await Fluttertoast.showToast(
                            msg: "Downloading ink recognizer model",
                            toastLength: Toast.LENGTH_SHORT);
                      }

                      context.loaderOverlay.show();

                      bool success = true;

                      if (!downloaded) {
                        try {
                          success = await modelManager
                              .downloadModel(selectedLanguageCode);
                        } catch (err) {
                          success = false;
                          logger.e(err);
                        }
                      }

                      if (success) {
                        final DigitalInkRecognizer _digitalInkRecognizer =
                            DigitalInkRecognizer(
                                languageCode: selectedLanguageCode);

                        String toastText = "Detected candidates:";
                        try {
                          final candidates =
                              await _digitalInkRecognizer.recognize(_ink);
                          detectedWord[0] = candidates[0].text;

                          for (final candidate in candidates) {
                            toastText += '\n- ${candidate.text}';
                          }
                        } catch (e) {
                          logger.e(e.toString());
                        }

                        await Fluttertoast.cancel();
                        await Fluttertoast.showToast(
                            msg: toastText, toastLength: Toast.LENGTH_LONG);

                        commonStorage.writeInMemory(
                            "detectedWord_temp", detectedWord);

                        _digitalInkRecognizer.close();
                      } else {
                        await Fluttertoast.cancel();
                        await Fluttertoast.showToast(
                            msg: "Ink recognizer model cannot be downloaded");
                      }
                      Get.back();
                    })
              ]).show();
          context.loaderOverlay.hide();

          // recreate Canvas with only the content
          PictureRecorder recorder = PictureRecorder();
          Canvas canvas = Canvas(recorder);

          // enter the loop
          final Paint paint = Paint()
            ..color = Colors.black
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 4.0;

          double top = 0;
          double left = 0;
          double right = 100;
          double bottom = 100;

          if (_ink.strokes.length > 0) {
            top = _ink.strokes[0].points[0].y.toDouble();
            left = _ink.strokes[0].points[0].x.toDouble();
            right = _ink.strokes[0].points[0].x.toDouble();
            bottom = _ink.strokes[0].points[0].y.toDouble();

            for (final stroke in _ink.strokes) {
              for (int i = 0; i < stroke.points.length - 1; i++) {
                final p1 = stroke.points[i];
                final p2 = stroke.points[i + 1];

                top = min(top, min(p1.y.toDouble(), p2.y.toDouble()));
                left = min(left, min(p1.x.toDouble(), p2.x.toDouble()));
                right = max(right, max(p1.x.toDouble(), p2.x.toDouble()));
                bottom = max(bottom, max(p1.y.toDouble(), p2.y.toDouble()));
              }
            }

            top = max(0, top - 5);
            left = max(0, left - 5);
            right += 5;
            bottom += 5;

            for (final stroke in _ink.strokes) {
              for (int i = 0; i < stroke.points.length - 1; i++) {
                final p1 = stroke.points[i];
                final p2 = stroke.points[i + 1];

                canvas.drawLine(
                    Offset(p1.x.toDouble() - left, p1.y.toDouble() - top),
                    Offset(p2.x.toDouble() - left, p2.y.toDouble() - top),
                    paint);
              }
            }
          }

          final picture = recorder.endRecording();
          final img = await picture.toImage(
              (right - left).toInt(), (bottom - top).toInt());
          final pngBytes = await img.toByteData(format: ImageByteFormat.png);
          await writeToFile(pngBytes!, widget.filePath);

          return true;
        },
        child: Scaffold(
          appBar: AppBar(title: Text('Handwriting')),
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    onPanStart: (DragStartDetails details) {
                      _ink.strokes.add(Stroke());
                    },
                    onPanUpdate: (DragUpdateDetails details) {
                      setState(() {
                        final RenderObject? object = context.findRenderObject();
                        final localPosition = (object as RenderBox?)
                            ?.globalToLocal(details.localPosition);
                        if (localPosition != null) {
                          _points = List.from(_points)
                            ..add(StrokePoint(
                              x: localPosition.dx,
                              y: localPosition.dy,
                              t: DateTime.now().millisecondsSinceEpoch,
                            ));
                        }
                        if (_ink.strokes.isNotEmpty) {
                          _ink.strokes.last.points = _points.toList();
                        }
                      });
                    },
                    onPanEnd: (DragEndDetails details) {
                      _points.clear();
                      setState(() {});
                    },
                    child: CustomPaint(
                      painter: Signature(ink: _ink),
                      size: Size.infinite,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ElevatedButton(
                      //   child: Text('Read Text'),
                      //   onPressed: _recogniseText,
                      // ),
                      ElevatedButton(
                        child: Text('Clear Pad'),
                        onPressed: _clearPad,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void _clearPad() {
    setState(() {
      _ink.strokes.clear();
      _points.clear();
    });
  }
}

class Signature extends CustomPainter {
  Ink ink;

  Signature({required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (final stroke in ink.strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(Offset(p1.x.toDouble(), p1.y.toDouble()),
            Offset(p2.x.toDouble(), p2.y.toDouble()), paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => true;
}
