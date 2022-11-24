import 'dart:io';
import 'dart:typed_data';

import 'package:english_words/english_words.dart' as ew;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

int fullVersionNoteAmount = 5;
const fullVersionProductId = "fullversion";
DateFormat dateFormat = DateFormat("EEEE, yyyy-MM-dd HH:mm");
const allPossibleSymbols = "!'§<>|\$%&/()=?\\`´+*#öäüÜÖÄ,.-;:_^{}[]";
var commonEnglishWords = ew.all +
    ["has", "had", "been", "was", "is", "are", "be", "am", "none", "an", "a"] +
    "1234567890".split('');
int inAppReviewNoteAmount = 8;
Duration inAppReviewDatetimeGap = const Duration(days: 3);
List<String> newNotePlaceholderOptions = [
  "Add note here. Ah, have you ever wondered how to learn things faster? Maybe Feynmann technique is the right one for you! "
      "1, Choose a concept to learn. "
      "2, Teach it to yourself or someone else. "
      "3, Return to the source material if you get stuck. "
      "4, Simplify your explainations and create analogies. "
      "Good luck in what you are doing right now 💪",
  "Add note here. Hmm, or list of groceries, or schedules. "
      "Hmm, I don't know. You can add whatever you want here. After all notes can be whatever you want 😊 "
      "Good luck in what you are doing right now 💪",
  "Add note here. Intro, body, conclusion. As simple as that, I guess 😉 "
      "The longer the better? The more succinct the better? Well, you are the boss. "
      "Good luck in what you are doing right now 💪"
];

Map<String, Color> noteCategories = {
  "none": Colors.white,
  "diary": Colors.lightBlueAccent,
  "presentation": Colors.lightGreenAccent,
  "work": Colors.redAccent,
  "lecture": Colors.limeAccent,
  "buy-list": Colors.orangeAccent
};

class CardData {
  String title;
  String description;
  bool? isStarred;
  void Function()? onTap;
  String? noteId;
  List<Widget>? trailing;
  String? editedAt;
  Widget? child;
  String? category;

  CardData(
      {required this.title,
      required this.description,
      this.isStarred,
      this.onTap,
      this.noteId,
      this.trailing,
      this.editedAt,
      this.child,
      this.category});
}

class Reminder {
  int id;
  DateTime? datetime;

  Reminder({required this.id, this.datetime});
}

int getAndIncrementStorageValue(String storageName, String key) {
  final storage = GetStorage(storageName);
  int value = storage.read(key) ?? -1;
  value = (value + 1) % 100;
  storage.write(key, value);
  return value;
}

String allWordsCapitilize(String value) {
  var result = value[0].toUpperCase();
  for (int i = 1; i < value.length; i++) {
    if (value[i - 1] == " ") {
      result = result + value[i].toUpperCase();
    } else {
      result = result + value[i];
    }
  }
  return result;
}

Future<void> writeToFile(ByteData data, String path) {
  final buffer = data.buffer;
  return File(path)
      .writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
}

Future<String?> getDownloadPath() async {
  Directory? directory;
  try {
    if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = Directory('/storage/emulated/0/Download');
      // Put file in global download folder, if for an unknown reason it didn't exist, we fallback
      // ignore: avoid_slow_async_io
      if (!await directory.exists())
        directory = await getExternalStorageDirectory();
    }
  } catch (err, stack) {
    logger.e("Cannot get download folder path");
  }
  return directory?.path;
}
