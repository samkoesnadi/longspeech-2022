import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:sicantik/helpers/delta_to_html.dart';
import 'package:sicantik/helpers/summarize.dart';
import 'package:sicantik/utils.dart';

// Map entityExtractionLanguageMap = {
//   "en": EntityExtractorLanguage.english,
//   "zh": EntityExtractorLanguage.chinese,
//   "ar": EntityExtractorLanguage.arabic,
//   "nl": EntityExtractorLanguage.dutch,
//   "fr": EntityExtractorLanguage.french,
//   "de": EntityExtractorLanguage.german,
//   "it": EntityExtractorLanguage.italian,
//   "ja": EntityExtractorLanguage.japanese,
//   "ko": EntityExtractorLanguage.korean,
//   "pl": EntityExtractorLanguage.polish,
//   "pt": EntityExtractorLanguage.portuguese,
//   "ru": EntityExtractorLanguage.russian,
//   "es": EntityExtractorLanguage.spanish,
//   "th": EntityExtractorLanguage.thai,
//   "tr": EntityExtractorLanguage.turkish
// };

Future<void> saveDocument(
    String noteId,
    String title,
    Document quillControllerDocument,
    bool isStarred,
    Map<String, dynamic> imageClassifications,
    List<String> voiceRecordings,
    List<String> videos,
    String noteCategory) async {
  final noteStorage = GetStorage("notes");

  // Update full text
  var json = jsonEncode(quillControllerDocument.toDelta().toJson());
  await noteStorage.write("$noteId-full", json);

  String plainText = '${quillControllerDocument.toPlainText()}. ';

  List keywords = await manageResources(
      quillControllerDocument, imageClassifications, voiceRecordings, videos);
  for (String keyword in keywords) {
    plainText += '$keyword. ';
  }

  Map<String, dynamic> aiAnalysisResult = await aiAnalysis(plainText);

  Map<String, dynamic> noteMetadata = noteStorage.read(noteId) ?? {};
  noteMetadata["title"] = title;
  noteMetadata["editedAt"] = DateTime.now().toString();
  noteMetadata["category"] = noteCategory;
  noteMetadata["summarized"] = aiAnalysisResult["summarized"];
  noteMetadata["wordCount"] = aiAnalysisResult["wordCount"];

  await noteStorage.write(noteId, noteMetadata);
  await noteStorage.write("$noteId-ners", aiAnalysisResult["entities"]);
  await noteStorage.write("$noteId-imageClassifications", imageClassifications);
  await noteStorage.write("$noteId-videos", videos);
  await noteStorage.write("$noteId-voiceRecordings", voiceRecordings);
  await noteStorage.write(
      "$noteId-detectedLanguages", aiAnalysisResult["detectedLanguages"]);
  await noteStorage.write("noteIds",
      ((noteStorage.read("noteIds") ?? []) + [noteId]).toSet().toList());
  await saveStarred(isStarred, noteId);
}

Future<List<String>> manageResources(
    Document quillControllerDocument,
    Map<String, dynamic> imageClassifications,
    List<String> voiceRecordings,
    List<String> videos) async {
  var json = jsonEncode(quillControllerDocument.toDelta().toJson());

  Map tempImageClassifications = Map.from(imageClassifications);
  List<String> keywords = [];
  for (final item in tempImageClassifications.entries) {
    // remove unused images
    if (!json.contains(item.key)) {
      try {
        await File(item.key).delete();
      } catch (err) {
        logger.e(err);
      }
      imageClassifications.remove(item.key);
    } else {
      keywords.addAll(item.value.cast<String>());
    }
  }

  List tempVoiceRecordings = [...voiceRecordings];
  for (String item in tempVoiceRecordings) {
    // remove unused images
    if (!json.contains(item)) {
      try {
        await File(item).delete();
      } catch (err) {
        logger.e(err);
      }
      voiceRecordings.removeWhere((elem) => elem == item);
    }
  }
  List tempVideos = [...videos];
  for (String item in tempVideos) {
    // remove unused images
    if (!json.contains(item)) {
      try {
        await File(item).delete();
      } catch (err) {
        logger.e(err);
      }
      videos.removeWhere((elem) => elem == item);
    }
  }

  return keywords.toSet().toList();
}

Future<void> deleteDocument(String noteId) async {
  final noteStorage = GetStorage("notes");
  final reminderStorage = GetStorage("reminders");

  List<String> noteIds = noteStorage.read("noteIds")?.cast<String>() ?? [];
  noteIds.removeWhere((element) => element == noteId);

  // remove all resources (images, videos and voice recordings)
  Map imageClassifications =
      noteStorage.read("$noteId-imageClassifications") ?? {};
  for (var entry in imageClassifications.entries) {
    try {
      await File(entry.key).delete();
    } catch (err) {
      logger.e(err);
    }
  }
  List videos = noteStorage.read("$noteId-videos") ?? [];
  for (var entry in videos) {
    try {
      await File(entry).delete();
    } catch (err) {
      logger.e(err);
    }
  }
  List voiceRecordings = noteStorage.read("$noteId-voiceRecordings") ?? [];
  for (var entry in voiceRecordings) {
    try {
      await File(entry).delete();
    } catch (err) {
      logger.e(err);
    }
  }

  await noteStorage.remove("$noteId-ners");
  await noteStorage.remove("$noteId-detectedLanguages");
  await noteStorage.remove("$noteId-imageClassifications");
  await noteStorage.remove(noteId);
  await noteStorage.write("noteIds", noteIds);

  await saveStarred(false, noteId);

  for (int noteId
      in (noteStorage.read("$noteId-reminders")?.cast<int>() ?? [])) {
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
  String summarized = "";
  List<String> entities = [];

  try {
    await Fluttertoast.showToast(msg: "Summarizing...");
    Map summarizedAndEntities =
        summarize(paragraph: plainText, amountOfSentences: 15);
    summarized = summarizedAndEntities["summarized"];
    entities = summarizedAndEntities["keywords"];
  } catch (e) {
    logger.e(e);
  }

  //// Identify text language
  await Fluttertoast.cancel();
  await Fluttertoast.showToast(msg: "Identifying language...");
  final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.1);
  final List<IdentifiedLanguage> possibleLanguages =
      await languageIdentifier.identifyPossibleLanguages(summarized);
  List<String> detectedLanguages = [];
  for (IdentifiedLanguage possibleLanguage in possibleLanguages) {
    detectedLanguages.add(possibleLanguage.languageTag);
  }
  languageIdentifier.close();
  await Fluttertoast.cancel();

  //// Identify ner
  // for (String detectedLanguage in detectedLanguages) {
  //   if (entityExtractionLanguageMap.containsKey(detectedLanguage)) {
  //     EntityExtractorLanguage entityExtractorLanguage =
  //         entityExtractionLanguageMap[detectedLanguage];
  //
  //     Fluttertoast.cancel();
  //     await Fluttertoast.showToast(
  //         msg:
  //             "Extracting entity for ${entityExtractorLanguage.toString().split('.').last}...");
  //     final entityExtractor =
  //         EntityExtractor(language: entityExtractorLanguage);
  //
  //     try {
  //       final List<EntityAnnotation> annotations =
  //           await entityExtractor.annotateText(summarized);
  //       entityExtractor.close();
  //
  //       for (final annotation in annotations) {
  //         // Only take the first entity type for simplicity
  //         entities
  //             .add("${annotation.entities[0].type.name}: ${annotation.text}");
  //       }
  //     } catch (e) {
  //       Fluttertoast.cancel();
  //       await Fluttertoast.showToast(
  //           msg:
  //               "Connect to internet if you want proper entity extraction result");
  //     }
  //   }
  // }

  // Count word
  int wordCount = RegExp(r"\w+").allMatches(plainText).length;

  return {
    "summarized": summarized,
    "entities": entities,
    "detectedLanguages": detectedLanguages,
    "wordCount": wordCount
  };
}

Future<File> exportToPDF(List json, String dirPath, String fileName) async {
  for (Map<String, dynamic> elem in json) {
    if (elem["insert"] is Map<String, dynamic>) {
      if (elem["insert"].containsKey("image")) {
        // elem["insert"]["image"] = elem["insert"]["image"].toString() +
        //     "' style='text-align:center; display:block;";
        if (!elem.containsKey("attributes")) {
          elem["attributes"] = {"style": "width: 50%; "};
        }
      }
    }
  }
  String htmlContent = jsonToHtml(json);
  htmlContent = htmlContent.replaceAll("src='/", "src='file:///");
  htmlContent = htmlContent.replaceAllMapped(
      RegExp(r"\bsrc='(https://.*)/watch\?v=([^&]+).*?'"), (Match match) {
    return "src='${match[1]}/embed/${match[2]}'";
  });

  var generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
      htmlContent, dirPath, fileName);

  return generatedPdfFile;
}
