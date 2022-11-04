import 'package:intl/intl.dart';

import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm");

class CardData {
  String title;
  String description;
  bool? isStarred;
  void Function()? onTap;
  String? noteId;
  List<Widget>? trailing;
  String? editedAt;
  Widget? child;

  CardData({
    required this.title,
    required this.description,
    this.isStarred,
    this.onTap,
    this.noteId,
    this.trailing,
    this.editedAt,
    this.child
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
