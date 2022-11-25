import 'dart:io' as io;

import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sicantik/utils.dart';

late ImageLabeler imageLabeler;

Future<String> getModel(String assetPath) async {
  if (io.Platform.isAndroid) {
    return 'flutter_assets/$assetPath';
  }
  final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
  await io.Directory(dirname(path)).create(recursive: true);
  final file = io.File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(assetPath);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}

Future initializeImageLabeler() async {
  const path = 'assets/ml/object_labeler.tflite';
  final modelPath = await getModel(path);
  final options = LocalLabelerOptions(
      confidenceThreshold: 0.25, maxCount: 30, modelPath: modelPath);
  imageLabeler = ImageLabeler(options: options);

  logger.d("ImageLabeler setup successfully");
}

Future processImageLabeling(String imageFilePath) async {
  final inputImage = InputImage.fromFilePath(imageFilePath);

  final labels = await imageLabeler.processImage(inputImage);
  return labels;
}
