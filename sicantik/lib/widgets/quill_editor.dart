import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sicantik/utils.dart';
import 'package:sicantik/widgets/flutter_quill_extensions.dart';
import 'package:tuple/tuple.dart';

class MyQuillEditor {
  QuillController quillController;
  FocusNode focusNode;

  MyQuillEditor({
    required this.quillController,
    required this.focusNode,
  });

  Future<String> _onImagePaste(Uint8List imageBytes) async {
    // Saves the image to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final file = await File(
            '${appDocDir.path}/${basename('${DateTime.now().millisecondsSinceEpoch}.png')}')
        .writeAsBytes(imageBytes, flush: true);
    return file.path.toString();
  }

  final _random = Random();

  QuillEditor generateQuillEditor(
      {bool readOnly = false,
      void Function(String)? onImageRemove,
      Map? imageArguments}) {
    return QuillEditor(
      controller: quillController,
      scrollController: ScrollController(),
      scrollable: true,
      showCursor: true,
      focusNode: focusNode,
      autoFocus: false,
      readOnly: readOnly,
      placeholder: newNotePlaceholderOptions[
          _random.nextInt(newNotePlaceholderOptions.length)],
      expands: false,
      padding: const EdgeInsets.all(15),
      onImagePaste: _onImagePaste,
      customStyles: DefaultStyles(
          h1: DefaultTextBlockStyle(
              const TextStyle(
                fontSize: 32,
                color: Colors.black,
                height: 1.15,
                fontWeight: FontWeight.w300,
              ),
              const Tuple2(16, 0),
              const Tuple2(0, 0),
              null),
          sizeSmall: const TextStyle(fontSize: 9)),
      embedBuilders: [
        ...FlutterQuillEmbeds.builders(
            onImageRemove: onImageRemove, imageArguments: imageArguments),
        AudioPlayerEmbedBuilder()
      ],
    );
  }
}
