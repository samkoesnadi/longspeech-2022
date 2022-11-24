import 'dart:async';

import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fuzzy/data/result.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:sicantik/helpers/document.dart';
import 'package:sicantik/screens/new_note_screen.dart';
import 'package:sicantik/screens/view_note_screen.dart';
import 'package:sicantik/theme_data.dart';
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
  late StreamSubscription<List<PurchaseDetails>> _inAppPurchaseSubscription;

  final TextEditingController _searchTextController =
      TextEditingController(text: "");
  final noteStorage = GetStorage("notes");
  final boxStorage = GetStorage();
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

    final Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    _inAppPurchaseSubscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _inAppPurchaseSubscription.cancel();
    }, onError: (error) {
      // handle error here.
    });

    // restore purchases from before
    InAppPurchase.instance.restorePurchases();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // bool valid = await _verifyPurchase(purchaseDetails);
          // if (valid) {
          //   _deliverProduct(purchaseDetails);
          // } else {
          //   // _handleInvalidPurchase(purchaseDetails);
          // // }
          if (purchaseDetails.productID == fullVersionProductId) {
            boxStorage.write(fullVersionProductId, true);
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    });
  }

  @override
  void dispose() {
    // _inAppPurchaseSubscription.cancel();
    super.dispose();
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
        iconColor: Colors.yellow,
        valueChanged: (isStarred) async {
          await saveStarred(isStarred, noteId);
        },
        isStarred: isStarred));
    trailing.add(IconButton(
        onPressed: () async {
          Alert(context: context, title: "Are you sure?", buttons: [
            DialogButton(color:grey.shade50, 
                child: Text(
                  "Yes",
                  style: TextStyle(
                      color:
                          Theme.of(context).primaryTextTheme.headline1?.color),
                ),
                onPressed: () async {
                  Get.back();
                  await deleteDocument(noteId);
                  cardDataObx
                      .removeWhere((element) => element.noteId == noteId);
                })
          ]).show();
        },
        icon: Icon(Icons.delete_outline)));
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
        editedAt: dateFormat.format(DateTime.parse(note["editedAt"])),
        category: note["category"] ?? "none");
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
                  color: Theme.of(context).primaryTextTheme.headline1?.color),
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

          // check fullVersion, if yes continue
          bool allowAddNote = true;
          if ((noteStorage.read("noteIds") ?? []).length >=
              fullVersionNoteAmount) {
            allowAddNote = boxStorage.read(fullVersionProductId) ?? false;
          }

          if (allowAddNote) {
            await Get.to(() => const NewNoteScreen());
          } else {
            await Alert(
                context: context,
                style: const AlertStyle(isOverlayTapDismiss: false),
                title: "Thank you for using the app so far!",
                desc:
                    "You can get the full app for more than $fullVersionNoteAmount notes. It is affordable 😊",
                buttons: [
                  DialogButton(color:grey.shade50,
                      child: Text("Check it out",
                          style: TextStyle(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .headline1
                                  ?.color)),
                      onPressed: () => Get.back())
                ]).show();

            bool available = await InAppPurchase.instance.isAvailable();
            if (available) {
              // Sell full version
              const Set<String> kIds = <String>{
                fullVersionProductId
              }; // keep it just one
              final ProductDetailsResponse response =
                  await InAppPurchase.instance.queryProductDetails(kIds);
              if (response.notFoundIDs.isNotEmpty) {
                // Handle the error.
                await Fluttertoast.showToast(
                    msg:
                        "Expressive Note app cannot find the item on Play Store");
                return;
              }
              List<ProductDetails> products = response.productDetails;

              for (ProductDetails product in products) {
                if (product.id == fullVersionProductId) {
                  final PurchaseParam purchaseParam =
                      PurchaseParam(productDetails: product);

                  await InAppPurchase.instance
                      .buyNonConsumable(purchaseParam: purchaseParam);
                  // From here the purchase flow will be handled by the underlying store.
                  // Updates will be delivered to the `InAppPurchase.instance.purchaseStream`.
                }
              }
            } else {
              await Fluttertoast.showToast(
                  msg:
                      "The Play Store cannot be accessed right now. No internet connection?");
            }
          }
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
