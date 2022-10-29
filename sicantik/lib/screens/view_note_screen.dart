import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sicantik/screens/new_note_screen.dart';
import 'package:sicantik/utils.dart';
import 'package:sicantik/widgets/list_view.dart';
import 'package:sicantik/widgets/scaffold.dart';

class ViewNoteScreen extends StatefulWidget {
  const ViewNoteScreen({Key? key}) : super(key: key);

  @override
  State<ViewNoteScreen> createState() => _ViewNoteScreenState();
}

class _ViewNoteScreenState extends State<ViewNoteScreen> {
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final noteStorage = GetStorage("notes");
  late String noteId;

  @override
  void initState() {
    Map<String, dynamic> arguments = Get.arguments;

    // IMPORTANT! noteId has to be defined
    noteId = arguments["noteId"];
    final noteJson = noteStorage.read("$noteId-full");
    final doc = Document.fromJson(jsonDecode(noteJson));
    _quillController = QuillController(
        document: doc, selection: const TextSelection.collapsed(offset: 0));
  }

  @override
  Widget build(BuildContext context) {
    var quillEditor = QuillEditor(
      controller: _quillController,
      scrollController: ScrollController(),
      scrollable: true,
      focusNode: _focusNode,
      autoFocus: true,
      readOnly: true,
      expands: false,
      padding: EdgeInsets.zero,
      embedBuilders: FlutterQuillEmbeds.builders(),
    );

    List<CardData> aiAnalysisCardData = [];
    aiAnalysisCardData.add(CardData(
        title: "Summary", description: noteStorage.read(noteId)["summarized"]));
    aiAnalysisCardData.add(CardData(title: "Detected languages",
        description: noteStorage.read("$noteId-detectedLanguages").join(", ")));
    aiAnalysisCardData.add(CardData(title: "Detected entities",
        description: noteStorage.read("$noteId-ners").join(", ")));

    return MyScaffold(
      floatingActionButtonIcon: Icons.edit,
      speedDialOnPress: () async {
        // set the arguments
        final dynamic arguments = {"noteId": noteId};

        await Get.to(() => const NewNoteScreen(), arguments: arguments);
      },
      body: TabBarView(children: [
        // view
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: quillEditor,
          ),
        ),
        // AI-assist
        Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shrinkWrap: true,
                    itemCount: aiAnalysisCardData.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(children: [
                        Text(aiAnalysisCardData[index].title),
                        Text(aiAnalysisCardData[index].description)
                      ]);
                    })))
      ]),
      title: noteStorage.read(noteId)["title"],);
  }
}
