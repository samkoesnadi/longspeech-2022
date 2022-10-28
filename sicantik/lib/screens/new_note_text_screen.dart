import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sicantik/screens/summarized_screen.dart';
import 'package:sicantik/widgets/scaffold.dart';

class NewNoteTextScreen extends StatefulWidget {
  const NewNoteTextScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NewNoteTextScreenState();
}

class _NewNoteTextScreenState extends State<NewNoteTextScreen> {
  Rx<IconData> floatingActionButtonController = (Icons.done).obs;
  TextEditingController textSentencesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
        fABLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButtonController: floatingActionButtonController,
        body: Column(children: <Widget>[
          const SizedBox(height: 10),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: textSentencesController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ))
        ]),
        title: Text("title".tr),
        onOpenFloatingActionButton: () async {
          Get.to(const SummarizedScreen(),
              arguments: {"text": textSentencesController.text});
        });
  }
}
