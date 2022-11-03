import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuple/tuple.dart';

import 'package:sicantik/helpers/summarize.dart';

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

final _entityExtractorModelManager = EntityExtractorModelManager();

Future<void> saveDocument(String noteId, String title,
    Document quillControllerDocument, bool isStarred) async {
  final noteStorage = GetStorage("notes");

  // Update full text
  var json = jsonEncode(quillControllerDocument.toDelta().toJson());
  await noteStorage.write("$noteId-full", json);

  Map<String, dynamic> aiAnalysisResult =
      await aiAnalysis(quillControllerDocument.toPlainText());

  Map<String, dynamic> noteMetadata = noteStorage.read(noteId) ?? {};
  noteMetadata["title"] = title;
  noteMetadata["editedAt"] = DateTime.now().toString();
  noteMetadata["summarized"] = aiAnalysisResult["summarized"];

  await noteStorage.write(noteId, noteMetadata);
  await noteStorage.write("$noteId-ners", aiAnalysisResult["entities"]);
  await noteStorage.write(
      "$noteId-detectedLanguages", aiAnalysisResult["detectedLanguages"]);
  await noteStorage.write("noteIds",
      ((noteStorage.read("noteIds") ?? []) + [noteId]).toSet().toList());
  await saveStarred(isStarred, noteId);
}

Future<void> deleteDocument(String noteId) async {
  final noteStorage = GetStorage("notes");
  final reminderStorage = GetStorage("reminders");

  List<String> noteIds = noteStorage.read("noteIds")?.cast<String>() ?? [];
  noteIds.removeWhere((element) => element == noteId);

  await noteStorage.remove("$noteId-ners");
  await noteStorage.remove("$noteId-detectedLanguages");
  await noteStorage.remove(noteId);
  await noteStorage.write("noteIds", noteIds);

  await saveStarred(false, noteId);

  for (int noteId in (noteStorage.read("$noteId-reminders")?.cast<int>() ?? [])) {
    reminderStorage.remove(noteId.toString());
  }
  noteStorage.remove("$noteId-reminders");
}

Future<void> saveStarred(bool isStarred, String noteId) async {
  final noteStorage = GetStorage("notes");

  List<String> allStarred = noteStorage.read("starred")?.cast<String>() ?? [];

  if (isStarred) {
    allStarred.add(noteId);
  } else {
    allStarred.removeWhere((element) => element == noteId);
  }

  await noteStorage.write("starred", allStarred);
}

Future<Map<String, dynamic>> aiAnalysis(String plainText) async {
  // Update AI analysis and metadata
  String summarized = summarize(paragraph: plainText, amountOfSentences: 15);

  //// Identify text language
  final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  final List<IdentifiedLanguage> possibleLanguages =
      await languageIdentifier.identifyPossibleLanguages(summarized);
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

      bool modelDownloaded = await _entityExtractorModelManager
          .isModelDownloaded(entityExtractorLanguage.name);

      if (modelDownloaded) {
        final List<EntityAnnotation> annotations =
            await entityExtractor.annotateText(summarized);
        entityExtractor.close();

        for (final annotation in annotations) {
          // Only take the first entity type for simplicity
          entities
              .add("${annotation.entities[0].type.name}: ${annotation.text}");
        }
      } else {
        Fluttertoast.showToast(
            msg:
                "Connect to internet if you want proper entity extraction result");
      }
    }
  }

  return {
    "summarized": summarized,
    "entities": entities,
    "detectedLanguages": detectedLanguages
  };
}


class MyQuillEditor {
  QuillController quillController;
  FocusNode focusNode;

  MyQuillEditor({
    required this.quillController,
    required this.focusNode,
  });

  Future<String> _onImagePaste(Uint8List imageBytes) async {
    // Saves the image to applications directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final file = await File(
        '${appDocDir.path}/${basename('${DateTime.now().millisecondsSinceEpoch}.png')}')
        .writeAsBytes(imageBytes, flush: true);
    return file.path.toString();
  }

  QuillEditor generateQuillEditor ({bool readOnly = false}) {
    return QuillEditor(
      controller: quillController,
      scrollController: ScrollController(),
      scrollable: true,
      focusNode: focusNode,
      autoFocus: false,
      readOnly: readOnly,
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
      )
    );
  }
}

