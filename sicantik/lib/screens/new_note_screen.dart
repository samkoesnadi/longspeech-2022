import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sicantik/helpers/speech_to_text.dart';
import 'package:sicantik/widgets/scaffold.dart';

class NewNoteScreen extends StatefulWidget {
  @override
  _NewNoteScreenState createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  late TextEditingController text_sentences_controller;
  late SpeechToTextHandler _speechToTextHandler;
  late MyScaffold scaffold;

  RxDouble sound_level = (0.0).obs;
  RxString last_result = "".obs;
  Rx<IconData> floating_action_button_controller = (Icons.mic_none).obs;
  Rx<double> sound_level_controller = (0.0).obs;

  late List<int> parsed_data;
  final Rx<IconData> curr_floatingActionButton_icon = (Icons.stop).obs;

  @override
  void initState() {
    super.initState();
    text_sentences_controller = TextEditingController();
    _speechToTextHandler = SpeechToTextHandler(
      soundLevelListener: (double level) {
        sound_level_controller.value = max(level, 0) * 1.5;
      },
      errorListener: (String error_text) {
        Future.delayed(Duration.zero, () {
          Alert(
            context: context,
            type: AlertType.error,
            title: error_text,
          ).show();
        });
      },
      partialResultListener: (String partial_text) {
        last_result.value = partial_text;
      },
      fullResultListener: (String full_text) {
        text_sentences_controller.text = full_text;
      },
    );
    parsed_data = [];

    // start recording immediately
    _speechToTextHandler.listen();
  }

  void ontap_callback() {
    _speechToTextHandler.stopListening();

    DateTime uuid = DateTime.now();

    // store the resulting text
    final notes_box = GetStorage("notes");
    List<DateTime>? uuids = notes_box.read("uuids");
    List<DateTime> new_uuids;
    if (uuids == null) {
      new_uuids = [uuid];
      notes_box.writeIfNull("uuids", [uuid]);
    } else {
      new_uuids = [...uuids, uuid];
    }
    notes_box.write("uuids", uuids);

    // summarize the resulting text

    // go to summarized screen
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
        floating_action_button_controller: floating_action_button_controller,
        sound_level_controller: sound_level_controller,
        body: Column(children: <Widget>[
          const SizedBox(height: 10),
          Container(
            child: Center(
              child: Obx(() =>
                  Text(
                    last_result.value,
                    textAlign: TextAlign.center,
                  )),
            ),
          ),
          const SizedBox(height: 10),
          Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: text_sentences_controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              )
          )
        ]),
        title: Text("title".tr),
        onTap_floatingActionButton: () {

        });
  }
}
