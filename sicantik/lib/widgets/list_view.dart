import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:sicantik/utils.dart';

Widget _wrapScrollTag(
        {required int index,
        required String noteId,
        required Widget child,
        required AutoScrollController scrollController}) =>
    AutoScrollTag(
      key: ValueKey(noteId),
      controller: scrollController,
      index: index,
      child: child,
    );

BoxScrollView generateListView(
    {required AutoScrollController scrollController,
    required List<CardData> cardData,
    Color? cardDividerColor}) {
  // divider for the card
  final cardDivider =
      Divider(thickness: 5, indent: 5, endIndent: 5, color: Colors.transparent);
  return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: cardData.length,
      itemBuilder: (BuildContext context, int index) {
        String headline = cardData[index].title;
        String description = cardData[index].description;
        String category = cardData[index].category ?? "none";

        const summarizedMaxLength = 150;
        const titleMaxLength = 100;

        if (description.length > summarizedMaxLength) {
          description = "${description.substring(0, summarizedMaxLength)}...";
        }
        if (headline.length > titleMaxLength) {
          headline = "${headline.substring(0, titleMaxLength)}...";
        }

        Widget titleWidget = ListTile(
            title: Text(headline,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
            trailing: Row(
                children: cardData[index].trailing!,
                mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
            ));

        String bottomCardText = cardData[index].editedAt!.toString();

        if (category != "none") {
          bottomCardText = '${category.capitalizeFirst!} : $bottomCardText';
        }

        return _wrapScrollTag(
            index: index,
            noteId: cardData[index].noteId ?? '',
            child: InkWell(
                onTap: cardData[index].onTap,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4.0,
                        offset: Offset(0.0, 4.0),
                      ),
                    ],
                  ),
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Column(
                            children: [
                              // the title
                              titleWidget,
                              // the description
                              Padding(
                                  padding: const EdgeInsets.only(
                                      left: 3, right: 3, bottom: 10),
                                  child: Text(
                                    description,
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  )),
                              Align(
                                  alignment: Alignment.topCenter,
                                  child: Text(bottomCardText))
                            ],
                          ))),
                )),
            scrollController: scrollController);
      });
}
