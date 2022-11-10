import 'dart:io';
import 'dart:typed_data';

import 'package:english_words/english_words.dart' as ew;
import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm");
const allPossibleSymbols = "!'§<>|\$%&/()=?\\`´+*#öäüÜÖÄ,.-;:_^{}[]";
var commonEnglishWords =
    ew.all + ["has", "had", "been", "was", "is", "are", "be", "am", "none"];
int inAppReviewNoteAmount = 8;
Duration inAppReviewDatetimeGap = const Duration(days: 3);

class CardData {
  String title;
  String description;
  bool? isStarred;
  void Function()? onTap;
  String? noteId;
  List<Widget>? trailing;
  String? editedAt;
  Widget? child;

  CardData(
      {required this.title,
      required this.description,
      this.isStarred,
      this.onTap,
      this.noteId,
      this.trailing,
      this.editedAt,
      this.child});
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
      if (!await directory.exists()) directory = await getExternalStorageDirectory();
    }
  } catch (err, stack) {
    print("Cannot get download folder path");
  }
  return directory?.path;
}
