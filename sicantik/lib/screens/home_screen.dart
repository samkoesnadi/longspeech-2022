import 'package:flutter/material.dart';
import 'package:fuzzy/data/result.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sicantik/screens/new_note_screen.dart';
import 'package:sicantik/utils.dart';
import 'package:sicantik/widgets/list_view.dart';
import 'package:sicantik/widgets/scaffold.dart';
import 'package:sicantik/widgets/scrollbar.dart';

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
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchTextController =
      TextEditingController(text: "");
  String titleText = "title".tr;
  final noteStorage = GetStorage("notes");
  List<CardData> fullCardData = [];
  RxList cardDataObx = [].obs;

  @override
  void initState() {
    _searchTextController.addListener(() async {
      if (_searchTextController.text != "") {
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
    List<String>? noteIds = noteStorage.read("noteIds");
    List<String> allStarred = noteStorage.read("starred") ?? [];

    Widget scaffoldBody;
    if (noteIds == null) {
      scaffoldBody = const SizedBox.shrink();
    } else {
      for (String noteId in noteIds) {
        Map<String, dynamic> note = noteStorage.read(noteId);
        fullCardData.add(CardData(
            title: note["title"],
            description: note["summarized"],
            isStarred: allStarred.contains(noteId)));
        cardDataObx.value = fullCardData;
      }

      scaffoldBody = Obx(() {
        List<CardData> cardData = cardDataObx.value.cast<CardData>();
        return scrollbarWrapper(
            child: generateListView(
                scrollController: scrollController, cardData: cardData),
            scrollController: scrollController,
            cardData: cardData);
      });
    }

    // get the cardData

    return MyScaffold(
      body: scaffoldBody,
      title: Obx(() => Text(
            titleText,
            overflow: TextOverflow.fade,
          )),
      floatingActionButtonIcon: Icons.add,
      speedDialOnPress: () async {
        await Get.to(() => const NewNoteScreen());
      },
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
