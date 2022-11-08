import 'package:flutter/material.dart';
import 'package:sicantik/utils.dart';

BoxScrollView generateListView(
    {required ScrollController scrollController,
    required List<CardData> cardData,
    Color? cardDividerColor}) {
  // divider for the card
  final cardDivider =
      Divider(thickness: 5, indent: 5, endIndent: 5, color: cardDividerColor);
  return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: cardData.length,
      itemBuilder: (BuildContext context, int index) {
        String headline = cardData[index].title;
        String description = cardData[index].description;

        List<Widget> titleRowContent = <Widget>[
          Expanded(child: cardDivider),
          Text(headline,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Expanded(child: cardDivider)
        ];
        if (cardData[index].trailing != null) {
          titleRowContent.addAll(cardData[index].trailing!);
        }
        Widget titleWidget = Row(children: titleRowContent);

        return InkWell(
            onTap: cardData[index].onTap,
            child: Container(
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
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
                          Padding(padding: EdgeInsets.all(5), child: Text(
                            description,
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          )),
                          Align(
                              alignment: Alignment.bottomRight,
                              child: Text(cardData[index].editedAt!))
                        ],
                      ))),
            ));
      });
}
