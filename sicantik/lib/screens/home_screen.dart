import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/data/result.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:sicantik/helpers/document.dart';
import 'package:sicantik/screens/new_note_screen.dart';
import 'package:sicantik/screens/view_note_screen.dart';
import 'package:sicantik/utils.dart';
import 'package:sicantik/widgets/bubble_showcase.dart';
import 'package:sicantik/widgets/list_view.dart';
import 'package:sicantik/widgets/scaffold.dart';
import 'package:sicantik/widgets/star_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

Set<int> search(List<String> input, String searchKey) {
  Fuzzy fuse = Fuzzy(input,
      options: FuzzyOptions(
          distance: 100000,
          threshold: 0.2,
          findAllMatches: true,
          isCaseSensitive: false,
          shouldNormalize: true));
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
  late AutoScrollController _scrollController;

  final TextEditingController _searchTextController =
      TextEditingController(text: "");
  final noteStorage = GetStorage("notes");
  List<CardData> fullCardData = [];
  RxList cardDataObx = [].obs;
  String? noteId;

  @override
  void initState() {
    _scrollController = AutoScrollController(
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: Axis.vertical);

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
      cardDataObx.refresh();
    });

    Map<String, dynamic>? arguments = Get.arguments;
    if (arguments != null && arguments.containsKey("noteId")) {
      noteId = Get.arguments["noteId"];
    }
  }

  void initCardData() {
    List<String> noteIds = noteStorage.read("noteIds")?.cast<String>() ?? [];
    List<String> allStarred = noteStorage.read("starred")?.cast<String>() ?? [];

    List beginning = [];
    List end = [];
    for (String noteId in noteIds) {
      if (allStarred.contains(noteId)) {
        beginning.add(noteId);
      } else {
        end.add(noteId);
      }
    }

    fullCardData = [];
    for (String noteId in beginning) {
      fullCardData.add(generateCardData(noteId, true));
    }
    for (String noteId in end) {
      fullCardData.add(generateCardData(noteId, false));
    }
    cardDataObx.value = fullCardData;
  }

  CardData generateCardData(String noteId, bool isStarred) {
    Map<String, dynamic> note = noteStorage.read(noteId);
    List<Widget> trailing = [];
    trailing.add(StarButton(
        iconColor: Theme.of(context).primaryColor,
        valueChanged: (isStarred) async {
          await saveStarred(isStarred, noteId);
        },
        isStarred: isStarred));
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
        icon:
            Icon(Icons.delete_outline, color: Theme.of(context).primaryColor)));
    String summarized = note["summarized"];
    String title = note["title"];

    return CardData(
        noteId: noteId,
        title: title,
        description: summarized,
        onTap: () async {
          await Get.to(() => const ViewNoteScreen(),
              arguments: {"noteId": noteId});
        },
        trailing: trailing,
        editedAt: dateFormat.format(DateTime.parse(note["editedAt"])));
  }

  GlobalKey buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    initCardData();

    Widget body = BubbleShowcaseHomeScreenWidget(
        buttonKey: buttonKey,
        child: Obx(() {
          // get the cardData
          List<CardData> cardData = cardDataObx.cast<CardData>();
          if (cardData.isEmpty) {
            return Center(
                child: Text(
                  "No note found",
                  style: TextStyle(
                      color:
                      Theme.of(context).primaryTextTheme.headline1?.color),
                ));
          }

          if (noteId != null) {
            int index =
            cardData.indexWhere((element) => element.noteId == noteId);
            _scrollController.scrollToIndex(index,
                preferPosition: AutoScrollPosition.begin);
          }

          return generateListView(
              scrollController: _scrollController,
              cardData: cardData,
              cardDividerColor: Colors.white);
        }));

    return MyScaffold(
        resizeToAvoidBottomInset: false,
        body: body,
        title: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 5, right: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("title".tr,
                    style:
                        TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                Obx(() => Text(
                      "${cardDataObx.length} notes",
                      style: TextStyle(fontSize: 14.0),
                    ))
              ],
            )),
        floatingActionButtonKey: buttonKey,
        floatingActionButtonIcon: Icons.note_add,
        speedDialOnPress: () async {
          const BubbleShowcaseNotification()..dispatch(context);
          await Get.to(() => const NewNoteScreen());
        },
        appBarActions: [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.help)),
        ],
        // appBarActions: [StreamBuilder(
        //     builder: (context, snapshot) {
        //       return Center(
        //           child: Text(dateFormat.format(DateTime.now()),
        //               style: const TextStyle(fontWeight: FontWeight.bold)));
        //     },
        //     stream: Stream.periodic(const Duration(seconds: 1)))],
        bottomNavigationBarChildren: [
          Expanded(
              child: ListTile(
            leading: const Icon(Icons.search),
            title: TextField(
                focusNode: FocusNode(),
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
        ]);
  }
}
