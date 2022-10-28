import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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
  late String title;

  @override
  void initState() {
    Map<String, dynamic> arguments = Get.arguments;

    title = "untitled".tr;
    if (arguments.containsKey("title")) {
      title = arguments["title"];
    }

    String noteId = "default";
    if (arguments.containsKey("noteId")) {
      noteId = arguments["noteId"];
    }
    final noteJson = noteStorage.read(noteId);
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

    return MyScaffold(
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
          Container()
        ]),
        title: Text(title),
        appBarBottom: TabBar(
          tabs: [
            Tab(text: "viewNote".tr),
            Tab(text: "AINote".tr),
          ],
        ));
  }
}
