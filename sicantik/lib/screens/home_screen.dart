import 'package:flutter/material.dart';
import 'package:fuzzy/data/result.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sicantik/helpers/document.dart';
import 'package:sicantik/screens/new_note_screen.dart';
import 'package:sicantik/screens/view_note_screen.dart';
import 'package:sicantik/utils.dart';
import 'package:sicantik/widgets/list_view.dart';
import 'package:sicantik/widgets/scaffold.dart';
import 'package:sicantik/widgets/star_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

Set<int> search(List<String> input, String searchKey) {
  Fuzzy fuse = Fuzzy(input);
  List<Result<dynamic>> result = fuse.search(searchKey);

  Set<int> searchResult = {};
  for (Result<dynamic> item in result) {
    for (ResultDetails<dynamic> resultDetail in item.matches) {
      searchResult.add(resultDetail.arrayIndex);
    }
  }

  return searchResult;
}

class HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchTextController =
  TextEditingController(text: "");
  String titleText = "title".tr;
  final noteStorage = GetStorage("notes");
  List<CardData> fullCardData = [];
  RxList cardDataObx = [].obs;

  @override
  void initState() {
    _searchTextController.addListener(() async {
      if (_searchTextController.text == "") {
        cardDataObx.value = fullCardData;
      } else {
        List<String> allTitle = fullCardData.map((e) => e.title).toList();
        List<String> allDescription =
        fullCardData.map((e) => e.description).toList();

        Set<int> searchResult = search(allTitle, _searchTextController.text);
        searchResult.addAll(search(allDescription, _searchTextController.text));

        cardDataObx.value = searchResult.map((e) => fullCardData[e]).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> noteIds = noteStorage.read("noteIds")?.cast<String>() ?? [];
    List<String> allStarred = noteStorage.read("starred")?.cast<String>() ?? [];

    fullCardData = [];
    for (String noteId in noteIds) {
      Map<String, dynamic> note = noteStorage.read(noteId);
      List<Widget> trailing = [];
      trailing.add(StarButton(
          iconColor: Theme
              .of(context)
              .primaryColor,
          valueChanged: (isStarred) async {
            await saveStarred(isStarred, noteId);
          },
          isStarred: allStarred.contains(noteId)));
      trailing.add(IconButton(
          onPressed: () async {
            Alert(context: context, title: "Are you sure?", buttons: [
              DialogButton(
                  child: const Text("Yes"),
                  onPressed: () async {
                    Get.back();
                    await deleteDocument(noteId);
                    cardDataObx
                        .removeWhere((element) => element.noteId == noteId);
                  })
            ]).show();
          },
          icon: Icon(Icons.delete, color: Theme
              .of(context)
              .primaryColor)));
      String summarized = note["summarized"];
      String title = note["title"];
      const summarizedMaxLength = 200;
      const titleMaxLength = 20;

      if (summarized.length > summarizedMaxLength) {
        summarized = "${summarized.substring(0, summarizedMaxLength)}...";
      }
      if (title.length > titleMaxLength) {
        title = "${title.substring(0, titleMaxLength)}...";
      }
      fullCardData.add(CardData(
          noteId: noteId,
          title: title,
          description: summarized,
          onTap: () async {
            await Get.to(() => const ViewNoteScreen(),
                arguments: {"noteId": noteId});
          },
          trailing: trailing,
          editedAt: dateFormat.format(DateTime.parse(note["editedAt"]))));
      cardDataObx.value = fullCardData;
    }

    // get the cardData

    return MyScaffold(
      resizeToAvoidBottomInset: false,
      body: Obx(() {
        List<CardData> cardData = cardDataObx.value.cast<CardData>();
        if (cardData.isEmpty) {
          return const Center(child: Text("Add note to begin the journey"));
        }
        return generateListView(
            scrollController: _scrollController,
            cardData: cardData,
            cardDividerColor: Theme
                .of(context)
                .primaryColor);
      }),
      title: Text(
        titleText,
        overflow: TextOverflow.fade,
      ),
      floatingActionButtonIcon: Icons.add,
      speedDialOnPress: () async {
        await Get.to(() => const NewNoteScreen());
      },
      appBarActions: [
        StreamBuilder(builder: (context, snapshot) {
          return Center(
              child: Text(dateFormat.format(DateTime.now()), style: TextStyle(fontWeight: FontWeight.bold))
          );
        }, stream: Stream.periodic(const Duration(seconds: 1)))
      ],
      bottomNavigationBarChildren: [
        Expanded(
            child: ListTile(
              leading: const Icon(Icons.search),
              title: TextField(
                  maxLength: 20,
                  controller: _searchTextController,
                  decoration: const InputDecoration(
                    hintText: "search note...",
                    hintStyle: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    counterText: "",
                  )),
            ))
      ],
    );
  }
}
