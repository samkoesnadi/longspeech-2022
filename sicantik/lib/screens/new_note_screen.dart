import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_tags/flutter_tags.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sicantik/helpers/document.dart';
import 'package:sicantik/screens/view_note_screen.dart';
import 'package:sicantik/utils.dart';
import 'package:sicantik/widgets/scaffold.dart';
import 'package:sicantik/widgets/star_button.dart';
import 'package:uuid/uuid.dart';

class NewNoteScreen extends StatefulWidget {
  const NewNoteScreen({Key? key}) : super(key: key);

  @override
  State<NewNoteScreen> createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  late QuillController _quillController;
  late TextEditingController _titleController;
  late MyQuillEditor myQuillEditor;
  final FocusNode _focusNode = FocusNode();
  final noteStorage = GetStorage("notes");
  late String noteId;
  late List<String> allStarred;
  bool isStarred = false;

  @override
  void initState() {
    Map<String, dynamic>? arguments = Get.arguments;

    int untitledNumber =
        getAndIncrementStorageValue("notes", "currentUntitledId");
    String title = "${"untitled".tr} $untitledNumber";
    Document doc = Document();

    if (arguments != null) {
      if (arguments.containsKey("noteId")) {
        noteId = arguments["noteId"];
        final noteJson = noteStorage.read("$noteId-full");
        doc = Document.fromJson(jsonDecode(noteJson));
        title = noteStorage.read(noteId)["title"];
      }
    } else {
      noteId = const Uuid().v4();
    }

    _titleController = TextEditingController(text: title);
    _quillController = QuillController(
        document: doc, selection: const TextSelection.collapsed(offset: 0));
    allStarred = noteStorage.read("starred")?.cast<String>() ?? [];

    _titleController.addListener(() {
      Map<String, String> noteMetadata = noteStorage.read(noteId) ?? {};
      noteMetadata["title"] = _titleController.text;
      noteStorage.write(noteId, noteMetadata);
    });

    myQuillEditor =
        MyQuillEditor(quillController: _quillController, focusNode: _focusNode);
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
        backgroundColor: Colors.white,
        body: Column(children: [
          // Reminder
          Flexible(
              fit: FlexFit.loose,
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) {
                  if (event.data.isControlPressed && event.character == 'b') {
                    if (_quillController
                        .getSelectionStyle()
                        .attributes
                        .keys
                        .contains('bold')) {
                      _quillController.formatSelection(
                          Attribute.clone(Attribute.bold, null));
                    } else {
                      _quillController.formatSelection(Attribute.bold);
                    }
                  }
                },
                child: _buildEditor(context),
              ))
        ]),
        title: Container(
            alignment: Alignment.centerLeft,
            color: Colors.white70,
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(border: InputBorder.none),
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            Alert(context: context, buttons: [
              DialogButton(
                  child: const Text("Cancel"), onPressed: () => Get.back()),
              DialogButton(
                  child: const Text("Discard"),
                  onPressed: () {
                    Get.back();
                    Get.back(); // get to the previous screen
                  }),
              DialogButton(
                  child: const Text("Save"),
                  onPressed: () async {
                    await saveDocument(noteId, _titleController.text,
                        _quillController.document, isStarred);
                    Get.off(() => const ViewNoteScreen(),
                        arguments: {"noteId": noteId});
                  })
            ]).show();
          },
        ),
        appBarActions: [
          StarButton(
              isStarred: allStarred.contains(noteId),
              iconColor: Colors.white,
              valueChanged: (_isStarred) {
                isStarred = _isStarred;
              }),
          IconButton(
              onPressed: () async {
                await saveDocument(noteId, _titleController.text,
                    _quillController.document, isStarred);

                Fluttertoast.showToast(msg: "The document is saved");
              },
              icon: const Icon(Icons.save))
        ]);
  }

  // Renders the image picked by imagePicker from local file storage
  // You can also upload the picked image to any server (eg : AWS s3
  // or Firebase) and then return the uploaded image URL.
  Future<String> _onImagePickCallback(File file) async {
    // Copies the picked file from temporary cache to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final copiedFile =
        await file.copy('${appDocDir.path}/${basename(file.path)}');
    return copiedFile.path.toString();
  }

  // Renders the video picked by imagePicker from local file storage
  // You can also upload the picked video to any server (eg : AWS s3
  // or Firebase) and then return the uploaded video URL.
  Future<String> _onVideoPickCallback(File file) async {
    // Copies the picked file from temporary cache to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final copiedFile =
        await file.copy('${appDocDir.path}/${basename(file.path)}');
    return copiedFile.path.toString();
  }

  Widget _buildEditor(BuildContext context) {
    var toolbar = QuillToolbar.basic(
      controller: _quillController,
      embedButtons: FlutterQuillEmbeds.buttons(
        // provide a callback to enable picking images from device.
        // if omit, "image" button only allows adding images from url.
        // same goes for videos.
        onImagePickCallback: _onImagePickCallback,
        onVideoPickCallback: _onVideoPickCallback,
        // uncomment to provide a custom "pick from" dialog.
        // mediaPickSettingSelector: _selectMediaPickSetting,
        // uncomment to provide a custom "pick from" dialog.
        // cameraPickSettingSelector: _selectCameraPickSetting,
      ),
      showAlignmentButtons: true,
      afterButtonPressed: _focusNode.requestFocus,
    );

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            flex: 15,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: myQuillEditor.generateQuillEditor(),
            ),
          ),
          Container(child: toolbar)
        ],
      ),
    );
  }
}
