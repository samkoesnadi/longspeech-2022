import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sicantik/helpers/speech_to_text.dart';
import 'package:sicantik/widgets/scaffold.dart';

class NewNoteSpeechToTextScreen extends StatefulWidget {
  const NewNoteSpeechToTextScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NewNoteSpeechToTextScreenState();
}

class _NewNoteSpeechToTextScreenState extends State<NewNoteSpeechToTextScreen> {
  late TextEditingController textSentencesController;
  late SpeechToTextHandler _speechToTextHandler;
  late MyScaffold scaffold;

  RxDouble soundLevel = (0.0).obs;
  RxString lastResult = "".obs;
  Rx<IconData> floatingActionButtonController = (Icons.mic_none).obs;
  Rx<double> soundLevelController = (0.0).obs;

  late List<int> parsedData;
  final Rx<IconData> currFloatingActionButtonIcon = (Icons.stop).obs;

  @override
  void initState() {
    super.initState();
    textSentencesController = TextEditingController();
    _speechToTextHandler = SpeechToTextHandler(
      soundLevelListener: (double level) {
        soundLevelController.value = max(level, 0) * 1.5;
      },
      errorListener: (String errorText) {
        Future.delayed(Duration.zero, () {
          Alert(
            context: context,
            type: AlertType.error,
            title: errorText,
          ).show();
        });
      },
      partialResultListener: (String partialText) {
        lastResult.value = partialText;
      },
      fullResultListener: (String fullText) {
        textSentencesController.text = fullText;
      },
    );
    parsedData = [];

    // start recording immediately
    _speechToTextHandler.listen();
  }

  void onTapCallback() {
    _speechToTextHandler.stopListening();

    DateTime uuid = DateTime.now();

    // store the resulting text
    final notesBox = GetStorage("notes");
    List<DateTime>? uuids = notesBox.read("uuids");
    List<DateTime> newUuids;
    if (uuids == null) {
      newUuids = [uuid];
      notesBox.writeIfNull("uuids", [uuid]);
    } else {
      newUuids = [...uuids, uuid];
    }
    notesBox.write("uuids", uuids);

    // summarize the resulting text

    // go to summarized screen
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
        fABLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButtonController: floatingActionButtonController,
        soundLevelController: soundLevelController,
        body: Column(children: <Widget>[
          const SizedBox(height: 10),
          Container(
            child: Center(
              child: Obx(() =>
                  Text(
                    lastResult.value,
                    textAlign: TextAlign.center,
                  )),
            ),
          ),
          const SizedBox(height: 10),
          Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: textSentencesController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              )
          )
        ]),
        title: Text("title".tr),
        onOpenFloatingActionButton: () {

        });
  }
}
