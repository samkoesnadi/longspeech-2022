import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:favorite_button/favorite_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sicantik/helpers/summarize.dart';
import 'package:sicantik/screens/view_note_screen.dart';
import 'package:sicantik/widgets/scaffold.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

Map entityExtractionLanguageMap = {
  "en": EntityExtractorLanguage.english,
  "zh": EntityExtractorLanguage.chinese,
  "ar": EntityExtractorLanguage.arabic,
  "nl": EntityExtractorLanguage.dutch,
  "fr": EntityExtractorLanguage.french,
  "de": EntityExtractorLanguage.german,
  "it": EntityExtractorLanguage.italian,
  "ja": EntityExtractorLanguage.japanese,
  "ko": EntityExtractorLanguage.korean,
  "pl": EntityExtractorLanguage.polish,
  "pt": EntityExtractorLanguage.portuguese,
  "ru": EntityExtractorLanguage.russian,
  "es": EntityExtractorLanguage.spanish,
  "th": EntityExtractorLanguage.thai,
  "tr": EntityExtractorLanguage.turkish
};

class NewNoteScreen extends StatefulWidget {
  const NewNoteScreen({Key? key}) : super(key: key);

  @override
  State<NewNoteScreen> createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  late QuillController _quillController;
  late TextEditingController _titleController;
  final FocusNode _focusNode = FocusNode();
  final noteStorage = GetStorage("notes");
  late String noteId;

  final _entityExtractorModelManager = EntityExtractorModelManager();

  @override
  void initState() {
    Map<String, dynamic>? arguments = Get.arguments;

    String title = "untitled".tr;
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

    _titleController.addListener(() {
      Map<String, String> noteMetadata = noteStorage.read(noteId);
      noteMetadata["title"] = _titleController.text;
      noteStorage.write(noteId, noteMetadata);
    });
  }

  void saveDocument() async {
    // Update full text
    var json = jsonEncode(_quillController.document.toDelta().toJson());
    noteStorage.write("$noteId-full", json);

    // Update AI analysis and metadata
    String plainText = _quillController.document.toPlainText();
    String summarized = summarize(paragraph: plainText);

    //// Identify text language
    final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
    final List<IdentifiedLanguage> possibleLanguages =
        await languageIdentifier.identifyPossibleLanguages(plainText);
    List<String> detectedLanguages = [];
    for (IdentifiedLanguage possibleLanguage in possibleLanguages) {
      detectedLanguages.add(possibleLanguage.languageTag);
    }
    languageIdentifier.close();

    //// Identify ner
    List<String> entities = [];
    for (String detectedLanguage in detectedLanguages) {
      if (entityExtractionLanguageMap.containsKey(detectedLanguage)) {
        EntityExtractorLanguage entityExtractorLanguage =
            entityExtractionLanguageMap[detectedLanguage];

        final entityExtractor =
            EntityExtractor(language: entityExtractorLanguage);

        _entityExtractorModelManager
            .isModelDownloaded(entityExtractorLanguage.name)
            .then((value) => Fluttertoast.showToast(
                msg:
                    "Connect to internet if you want proper entity extraction result"));

        final List<EntityAnnotation> annotations =
            await entityExtractor.annotateText(plainText);

        for (final annotation in annotations) {
          // Only take the first entity type for simplicity
          entities
              .add("${annotation.entities[0].type.name}: ${annotation.text}");
        }
        entityExtractor.close();
      }
    }

    Map<String, String> noteMetadata = noteStorage.read(noteId) ?? {};
    noteMetadata["title"] = _titleController.text;
    noteMetadata["editedAt"] = DateTime.now().toString();
    noteMetadata["summarized"] = summarized;
    noteStorage.write(noteId, noteMetadata);
    noteStorage.write("$noteId-ners", entities);
    noteStorage.write("$noteId-detectedLanguages", detectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    // check if starred or not
    List<String> allStarred = noteStorage.read("starred") ?? [];

    return MyScaffold(
        body: Column(children: [
          // TODO: Reminder
          Container(),
          Padding(
              padding: const EdgeInsets.only(top: 10),
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
        title: TextField(
          controller: _titleController,
          decoration:
              const InputDecoration(filled: true, fillColor: Color(0x00ffffff)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            Alert(
              context: context,
              buttons: [
                DialogButton(child: const Text("Cancel"), onPressed: () => Get.back()),
                DialogButton(child: const Text("Discard"), onPressed: () {
                  Get.back();
                  Get.back();  // get to the previous screen
                }),
                DialogButton(child: const Text("Save"), onPressed: () {
                  saveDocument();
                  Get.off(() => const ViewNoteScreen(), arguments: {
                    "noteId": noteId
                  });
                })
              ]
            ).show();
          },
        ),
        appBarActions: [
          IconButton(
            onPressed: () => _addEditNote(context),
            icon: const Icon(Icons.speaker_notes),
          ),
          StarButton(isStarred: allStarred.contains(noteId), valueChanged: (isStarred) {
            Set<String> allStarredSet = allStarred.toSet();

            if (isStarred) {
              allStarredSet.add(noteId);
            } else {
              allStarredSet.remove(noteId);
            }

            noteStorage.write("starred", allStarredSet.toList());
          }),
          IconButton(
              onPressed: () {
                saveDocument();

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
    var quillEditor = QuillEditor(
      controller: _quillController,
      scrollController: ScrollController(),
      scrollable: true,
      focusNode: _focusNode,
      autoFocus: false,
      readOnly: false,
      placeholder: 'Add content',
      expands: false,
      padding: EdgeInsets.zero,
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
        sizeSmall: const TextStyle(fontSize: 9),
      ),
      embedBuilders: [
        ...FlutterQuillEmbeds.builders(),
        NotesEmbedBuilder(addEditNote: _addEditNote)
      ],
    );
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
              child: quillEditor,
            ),
          ),
          Container(child: toolbar)
        ],
      ),
    );
  }

  Future<String> _onImagePaste(Uint8List imageBytes) async {
    // Saves the image to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final file = await File(
            '${appDocDir.path}/${basename('${DateTime.now().millisecondsSinceEpoch}.png')}')
        .writeAsBytes(imageBytes, flush: true);
    return file.path.toString();
  }

  Future<void> _addEditNote(BuildContext context, {Document? document}) async {
    final isEditing = document != null;
    final quillEditorController = QuillController(
      document: document ?? Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.only(left: 16, top: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${isEditing ? 'Edit' : 'Add'} note'),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            )
          ],
        ),
        content: QuillEditor.basic(
          controller: quillEditorController,
          readOnly: false,
        ),
      ),
    );

    if (quillEditorController.document.isEmpty()) return;

    final block = BlockEmbed.custom(
      NotesBlockEmbed.fromDocument(quillEditorController.document),
    );
    final controller = _quillController;
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;

    if (isEditing) {
      final offset = getEmbedNode(controller, controller.selection.start).item1;
      controller.replaceText(
          offset, 1, block, TextSelection.collapsed(offset: offset));
    } else {
      controller.replaceText(index, length, block, null);
    }
  }
}

class NotesEmbedBuilder implements EmbedBuilder {
  NotesEmbedBuilder({required this.addEditNote});

  Future<void> Function(BuildContext context, {Document? document}) addEditNote;

  @override
  String get key => 'notes';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
  ) {
    final notes = NotesBlockEmbed(node.value.data).document;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: Text(
          notes.toPlainText().replaceAll('\n', ' '),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const Icon(Icons.notes),
        onTap: () => addEditNote(context, document: notes),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}

class NotesBlockEmbed extends CustomBlockEmbed {
  const NotesBlockEmbed(String value) : super(noteType, value);

  static const String noteType = 'notes';

  static NotesBlockEmbed fromDocument(Document document) =>
      NotesBlockEmbed(jsonEncode(document.toDelta().toJson()));

  Document get document => Document.fromJson(jsonDecode(data));
}
