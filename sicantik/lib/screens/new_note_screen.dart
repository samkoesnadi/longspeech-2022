import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sicantik/helpers/speech_to_text.dart';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:sicantik/widgets/scaffold.dart';


class NewNoteScreen extends StatefulWidget {
  @override
  _NewNoteScreenState createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  late TextEditingController text_sentences_controller;
  final SpeechToTextHandler _speechToTextHandler = SpeechToTextHandler();
  late MyScaffold scaffold;

  RxDouble sound_level = (0.0).obs;

  late List<int> parsed_data;
  final Rx<IconData> curr_floatingActionButton_icon = (Icons.stop).obs;

  @override
  void initState() {
    super.initState();
    text_sentences_controller = TextEditingController();
    parsed_data = [];
    scaffold = MyScaffold(
        body: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: text_sentences_controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            )),
        title: Text("title".tr),
        default_floatingActionButton_icon: Icons.mic_none,
        onTap_floatingActionButton: (curr_floatingActionButton_icon) {
          _speechToTextHandler.stopListening();
        }
    );


    // start recording immediately
    _speechToTextHandler.listen();
  }

  void soundLevelListener(double level) {
    scaffold.sound_level = level;
  }

  @override
  Widget build(BuildContext context) {
    return scaffold;
  }
}
