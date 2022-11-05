import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/embeds/widgets/image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sicantik/helpers/document.dart';
import 'package:sicantik/helpers/flutter_quill_extensions.dart';
import 'package:sicantik/helpers/image_labeler.dart';
import 'package:sicantik/helpers/speech_to_text.dart';
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
  late Map<String, dynamic> imageClassifications;

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

    myQuillEditor =
        MyQuillEditor(quillController: _quillController, focusNode: _focusNode);

    imageClassifications =
        noteStorage.read("$noteId-imageClassifications") ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          await Alert(
              context: context,
              style: const AlertStyle(isOverlayTapDismiss: false),
              title: "What should we do with this document, boss?",
              buttons: [
                DialogButton(
                    child: const Text("Cancel"), onPressed: () => Get.back()),
                DialogButton(
                    child: const Text("Discard"),
                    onPressed: () {
                      Get.back();
                      if (noteStorage.hasData(noteId)) {
                        Get.off(() => const ViewNoteScreen(),
                            arguments: {"noteId": noteId});
                      } else {
                        Get.back();
                      }
                    }),
                DialogButton(
                    child: const Text("Save"),
                    onPressed: () async {
                      Get.back();
                      await saveDocument(
                          noteId,
                          _titleController.text,
                          _quillController.document,
                          isStarred,
                          imageClassifications);
                      Fluttertoast.showToast(msg: "The document is saved");
                      Get.off(() => const ViewNoteScreen(),
                          arguments: {"noteId": noteId});
                    })
              ]).show();
          return false;
        },
        child: MyScaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.white,
            body: Column(children: [
              const Padding(padding: EdgeInsets.all(5)),
              Flexible(
                  fit: FlexFit.loose,
                  child: RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (event) {
                      if (event.data.isControlPressed &&
                          event.character == 'b') {
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
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(border: InputBorder.none),
                )),
            appBarActions: [
              StarButton(
                  isStarred: allStarred.contains(noteId),
                  iconColor: Colors.white,
                  valueChanged: (_isStarred) {
                    isStarred = _isStarred;
                  }),
              IconButton(
                  onPressed: () async {
                    await saveDocument(
                        noteId,
                        _titleController.text,
                        _quillController.document,
                        isStarred,
                        imageClassifications);

                    Fluttertoast.showToast(msg: "The document is saved");
                  },
                  icon: const Icon(Icons.save))
            ]));
  }

  // Renders the image picked by imagePicker from local file storage
  // You can also upload the picked image to any server (eg : AWS s3
  // or Firebase) and then return the uploaded image URL.
  Future<String> _onImagePickCallback(File file) async {
    // Copies the picked file from temporary cache to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final copiedFile =
        await file.copy('${appDocDir.path}/${basename(file.path)}');

    // Process image labeling
    final labels = await processImageLabeling(copiedFile.path);

    String toastText = 'Detected labels:';
    List<String> detectedObjects = [];
    if (labels.length == 0) {
      toastText += "none";
    } else {
      for (final label in labels) {
        if (label.confidence > 0.1) {
          toastText += '\n- ${label.label}, '
              'confidence: ${label.confidence.toStringAsFixed(2)}';
          detectedObjects.add(label.label);
        }
      }
    }
    String localPath = copiedFile.path.toString();

    imageClassifications[standardizeImageUrl(localPath)] = detectedObjects;
    Fluttertoast.showToast(msg: toastText, toastLength: Toast.LENGTH_LONG);

    return localPath;
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
      toolbarIconSize: 21,
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
          ) +
          [
            (controller, toolbarIconSize, iconTheme, dialogTheme) {
              return QuillIconButton(
                icon: Icon(Icons.mic,
                    size: toolbarIconSize,
                    color: iconTheme?.iconUnselectedColor),
                highlightElevation: 0,
                hoverElevation: 0,
                size: toolbarIconSize * 1.77,
                fillColor: Colors.lightGreenAccent,
                borderRadius: iconTheme?.borderRadius ?? 2,
                onPressed: () async {
                  final controller = _quillController;
                  final index = controller.selection.baseOffset;
                  final length = controller.selection.extentOffset - index;

                  if (!await SpeechToTextHandler.preInitSpeechState()) {
                    Alert(
                            context: context,
                            type: AlertType.error,
                            title: "No speech")
                        .show();
                  } else {
                    Alert(
                      context: context,
                      content: Flex(
                        direction: Axis.vertical,
                        children: [
                          const Text('Language:'),
                          StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return DropdownButton<String>(
                              isExpanded: true,
                              onChanged: (selectedVal) {
                                setState(() {
                                  if (selectedVal != null) {
                                    SpeechToTextHandler.currentLocaleId =
                                        selectedVal;
                                  }
                                });
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
                            );
                          })
                        ],
                      ),
                      buttons: [
                        DialogButton(
                          child: const Text("OK"),
                          onPressed: () async {
                            Get.back();

                            final partialTextController =
                                "Waiting for input...".obs;
                            final speechToTextHandler = SpeechToTextHandler(
                                partialResultListener: (String partialText,
                                    String fullText, int lastTextCount) {
                              partialTextController.value =
                                  SpeechToTextHandler.combineSentences(
                                      fullText, lastTextCount, partialText)[0];
                              partialTextController.refresh();
                            }, errorListener: (String errorText) {
                              partialTextController.value = "Error: $errorText";
                              partialTextController.refresh();
                            });
                            speechToTextHandler.listen();
                            Alert(
                                context: context,
                                content: Obx(
                                    () => Text(partialTextController.value)),
                                buttons: [
                                  DialogButton(
                                    child: const Text("Stop"),
                                    onPressed: () {
                                      speechToTextHandler.stopListening();
                                      Get.back();

                                      String fullText =
                                          "${speechToTextHandler.fullText}. ";
                                      controller.replaceText(
                                          index,
                                          length,
                                          fullText,
                                          TextSelection.collapsed(
                                              offset: index + fullText.length));
                                    },
                                  )
                                ],
                                closeFunction: () {
                                  speechToTextHandler.stopListening();
                                }).show();
                          },
                        )
                      ],
                    ).show();
                  }
                },
              );
            }
          ],
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
              child: myQuillEditor.generateQuillEditor(
                  onImageRemove: (String imageUrl) {
                    File(imageUrl).delete();
                    imageClassifications.remove(imageUrl);
                  },
                  imageArguments: imageClassifications),
            ),
          ),
          Container(child: toolbar)
        ],
      ),
    );
  }
}
