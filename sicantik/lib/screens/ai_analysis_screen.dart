import 'package:favorite_button/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sicantik/widgets/scaffold.dart';
import 'package:uuid/uuid.dart';

class AIAnalysisScreen extends StatelessWidget {
  AIAnalysisScreen({Key? key}) : super(key: key);
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    // Check if ID exists.
    // If so, get the data from the storage, otherwise summarize it

    Map<String, dynamic> arguments = Get.arguments;
    String id;
    if (arguments.containsKey("id")) {
      id = arguments["id"];
    } else {
      id = _uuid.v4();
      String text = arguments["text"];
    }

    return MyScaffold(
      body: Column(children: <Widget>[
        StarButton(valueChanged: (isStarred) {}, isStarred: false)
      ]),
      title: Text(id, overflow: TextOverflow.fade),
    );
  }
}
