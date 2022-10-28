import 'package:favorite_button/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sicantik/helpers/summarize.dart';
import 'package:sicantik/utils.dart';
import 'package:sicantik/widgets/scaffold.dart';

class SummarizedScreen extends StatelessWidget {
  const SummarizedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if ID exists.
    // If so, get the data from the storage, otherwise summarize it

    Map<String, dynamic> arguments = Get.arguments;
    String id;
    List<Sentence> sentences = [];
    if (arguments.containsKey("id")) {
      id = arguments["id"];
    } else {
      id = uuid.v4();
      String text = arguments["text"];

      sentences = summarize(paragraph: text);
    }

    const highlightStyle = TextStyle(
        fontWeight: FontWeight.bold, decoration: TextDecoration.underline);

    List<TextSpan> textSpans = sentences
        .map((sentence) => TextSpan(
            text: sentence.sentence,
            style: (sentence.summarized) ? highlightStyle : null))
        .toList();

    return MyScaffold(
      body: Column(children: <Widget>[
        StarButton(valueChanged: (isStarred) {}, isStarred: false),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyText1,
            children: textSpans,
          ),
        )
      ]),
      title: Text(id, overflow: TextOverflow.fade),
    );
  }
}
