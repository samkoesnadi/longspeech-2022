import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sicantik/helpers/speech_to_text.dart';
import 'package:sicantik/screens/new_note_speech_to_text_screen.dart';
import 'package:sicantik/screens/new_note_text_screen.dart';
import 'package:sicantik/utils.dart';
import 'package:sicantik/widgets/list_view.dart';
import 'package:sicantik/widgets/scaffold.dart';
import 'package:sicantik/widgets/scrollbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchTextController =
      TextEditingController(text: "");
  RxString title_text = "title".tr.obs;
  final noteStorage = GetStorage("notes");

  @override
  void initState() {
    _searchTextController.addListener(() {
      if (_searchTextController.text == "") {
        title_text.value = "title".tr;
      } else {
        title_text.value = _searchTextController.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String>? noteIds = noteStorage.read("noteIds");

    Widget scaffoldBody;
    if (noteIds == null) {
      scaffoldBody = const SizedBox.shrink();
    } else {
      List<CardData> cardData = [];
      for (String noteId in noteIds) {
        Map<String, dynamic> note = noteStorage.read(noteId);
        cardData
            .add(CardData(title: note["title"], description: note["summarized"]));
      }

      scaffoldBody = scrollbar_wrapper(
          child: generateListView(
              scrollController: scrollController, cardData: cardData),
          scrollController: scrollController,
          cardData: cardData);
    }

    // get the cardData

    return MyScaffold(
      body: scaffoldBody,
      title: Obx(() => Text(
            title_text.value,
            overflow: TextOverflow.fade,
          )),
      onOpenFloatingActionButton: () async {
        final fuse = Fuzzy(['apple', 'banana', 'orange']);
        final result = fuse.search('ran');
        result.map((r) => r.item).forEach(print);
      },
      speedDialChildren: [
        SpeedDialChild(
          child: const Icon(Icons.note_add),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          label: 'Text note',
          onTap: () async {
            await Get.to(() => const NewNoteTextScreen());
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.mic_none_rounded),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          label: 'Text-to-speech note',
          onTap: () async {
            if (!await SpeechToTextHandler.preInitSpeechState()) {
              Alert(context: context, type: AlertType.error, title: "No speech")
                  .show();
            } else {
              Alert(
                context: context,
                content: Flex(
                  direction: Axis.vertical,
                  children: [
                    const Text('Language:'),
                    DropdownButton<String>(
                      isExpanded: true,
                      onChanged: (selectedVal) {
                        if (selectedVal != null) {
                          SpeechToTextHandler.currentLocaleId = selectedVal;
                        }
                      },
                      value: SpeechToTextHandler.currentLocaleId,
                      items: SpeechToTextHandler.localeNames
                          .map(
                            (localeName) => DropdownMenuItem(
                              value: localeName.localeId,
                              child: Text(localeName.name,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                buttons: [
                  DialogButton(
                    child: const Text("OK"),
                    onPressed: () async {
                      await Get.to(() => NewNoteSpeechToTextScreen());
                      Get.back();
                    },
                  )
                ],
              ).show();
            }
          },
        )
      ],
      bottomNavigationBarChildren: [
        Expanded(
            child: ListTile(
          leading: Icon(Icons.search),
          title: TextField(
              maxLength: 20,
              controller: _searchTextController,
              decoration: const InputDecoration(
                hintText: "search note...",
                hintStyle: TextStyle(
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                counterText: "",
              )),
        ))
      ],
    );
  }
}
