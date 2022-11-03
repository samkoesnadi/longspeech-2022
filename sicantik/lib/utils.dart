import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

class CardData {
  String title;
  String description;
  bool? isStarred;
  void Function()? onTap;
  String? noteId;
  List<Widget>? trailing;

  CardData({
    required this.title,
    required this.description,
    this.isStarred,
    this.onTap,
    this.noteId,
    this.trailing
  });
}

class Reminder {
  int id;
  DateTime? datetime;

  Reminder({
    required this.id,
    this.datetime
  });
}

int getAndIncrementStorageValue(String storageName, String key) {
  final storage = GetStorage(storageName);
  int value = storage.read(key) ?? -1;
  value = (value + 1) % 100;
  storage.write(key, value);
  return value;
}
