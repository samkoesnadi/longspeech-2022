import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_tags/flutter_tags.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sicantik/helpers/document.dart';
import 'package:sicantik/helpers/notification.dart';
import 'package:sicantik/screens/home_screen.dart';
import 'package:sicantik/screens/new_note_screen.dart';
import 'package:sicantik/utils.dart';
import 'package:sicantik/widgets/bubble_showcase.dart';
import 'package:sicantik/widgets/flutter_quill_extensions.dart';
import 'package:sicantik/widgets/quill_editor.dart';
import 'package:sicantik/widgets/scaffold.dart';
import 'package:timezone/timezone.dart' as tz;

class ViewNoteScreen extends StatefulWidget {
  const ViewNoteScreen({Key? key}) : super(key: key);

  @override
  State<ViewNoteScreen> createState() => _ViewNoteScreenState();
}

class _ViewNoteScreenState extends State<ViewNoteScreen>
    with TickerProviderStateMixin {
  late QuillController _quillController;
  late TabController _tabController;
  final FocusNode _focusNode = FocusNode();
  late MyQuillEditor myQuillEditor;
  final noteStorage = GetStorage("notes");
  final reminderStorage = GetStorage("reminders");

  RxList reminders = [].obs;
  late String noteId;

  @override
  void initState() {
    Map<String, dynamic> arguments = Get.arguments;

    // IMPORTANT! noteId has to be defined
    noteId = arguments["noteId"];
    final noteJson = noteStorage.read("$noteId-full");
    final doc = Document.fromJson(jsonDecode(noteJson));
    _quillController = QuillController(
        document: doc, selection: const TextSelection.collapsed(offset: 0));
    _tabController = TabController(length: 3, vsync: this);

    myQuillEditor =
        MyQuillEditor(quillController: _quillController, focusNode: _focusNode);

    // initiate reminders
    List<int> reminderIds =
        noteStorage.read("$noteId-reminders")?.cast<int>() ?? [];
    reminders.clear();
    for (int reminderId in reminderIds) {
      if (reminderStorage.hasData(reminderId.toString())) {
        String datetimeStr = reminderStorage.read(reminderId.toString());
        DateTime datetime = DateTime.parse(datetimeStr);
        reminders.add(Reminder(id: reminderId, datetime: datetime));
      }
    }
  }

  @override
  void dispose() {
    globalAudioPlayers = {};
    super.dispose();
  }

  GlobalKey tabBarGlobalKey = GlobalKey();
  GlobalKey appBarGlobalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    List<String> detectedLanguageCodes =
        noteStorage.read("$noteId-detectedLanguages")!.cast<String>();
    List<String> detectedLanguages = detectedLanguageCodes
        .map((elem) =>
            LocaleNames.of(context)!.nameOf(elem.substring(0, 2)) ??
            "unidentified".tr)
        .toList(); // null

    Map<String, dynamic> noteMetadata = noteStorage.read(noteId)!;
    Map imageClassifications =
        noteStorage.read("$noteId-imageClassifications") ?? {};
    List<CardData> aiAnalysisCardData = [];
    aiAnalysisCardData.add(CardData(
        title: "Detected keywords",
        description: noteStorage.read("$noteId-ners").join(", ")));
    aiAnalysisCardData.add(CardData(
        title: "Detected languages",
        description: detectedLanguages.join(", ")));
    aiAnalysisCardData.add(CardData(
        title: "Words count",
        description: noteMetadata["wordCount"].toString()));
    aiAnalysisCardData.add(CardData(
        title: "Edited at",
        description:
            dateFormat.format(DateTime.parse(noteMetadata['editedAt']))));
    aiAnalysisCardData.add(CardData(
        title: "Category",
        description: noteMetadata["category"] ?? "none"));
    aiAnalysisCardData.add(
        CardData(title: "Summary", description: noteMetadata["summarized"]));

    String title = noteMetadata["title"];
    String description = noteMetadata["summarized"];

    return WillPopScope(
        onWillPop: () async {
          await Get.offAll(() => const HomeScreen(),
              arguments: {"noteId": noteId});

          int notesAmount = (noteStorage.read("noteIds") ?? []).length;
          Map? inAppReviewTrack = noteStorage.read("$noteId-inAppReviewTrack");
          bool askReview = false;
          if (notesAmount % inAppReviewNoteAmount == 0) {
            if (inAppReviewTrack != null) {
              if (!inAppReviewTrack["done"]) {
                DateTime dateTimeNow = DateTime.now();
                if (dateTimeNow.difference(
                        DateTime.parse(inAppReviewTrack["datetime"])) >=
                    inAppReviewDatetimeGap) {
                  askReview = true;
                }
              }
            } else {
              askReview = true;
            }

            if (askReview) {
              bool done = false;
              DateTime datetime = DateTime.now();
              final InAppReview inAppReview = InAppReview.instance;
              if (await inAppReview.isAvailable()) {
                inAppReview.requestReview().then((value) {
                  done = true;
                });
                noteStorage.write("$noteId-inAppReviewTrack",
                    {"done": done, "datetime": datetime.toString()});
              }
            }
          }

          return false;
        },
        child: MyScaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.white,
          floatingActionButtonIcon: Icons.edit,
          speedDialOnPress: () async {
            // set the arguments
            final dynamic arguments = {"noteId": noteId};

            await Get.to(() => const NewNoteScreen(), arguments: arguments);
          },
          appBarKey: appBarGlobalKey,
          appBarBottom: TabBar(
              indicatorColor: noteCategories[noteMetadata["category"] ?? "none"],
              key: tabBarGlobalKey,
              controller: _tabController,
              tabs: [
                Tab(text: "View"),
                Tab(text: "Insights"),
                Tab(text: "Reminders")
              ]),
          body: BubbleShowcaseViewNoteWidget(
              tabBarGlobalKey: tabBarGlobalKey,
              appBarGlobalKey: appBarGlobalKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // view
                  Padding(
                    padding: const EdgeInsets.all(0),
                    child: Container(
                      child: myQuillEditor.generateQuillEditor(
                          readOnly: true, imageArguments: imageClassifications),
                    ),
                  ),
                  // AI-assist
                  Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                          child: Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  shrinkWrap: true,
                                  itemCount: aiAnalysisCardData.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    String description = "none";
                                    if (aiAnalysisCardData[index].description !=
                                        "") {
                                      description =
                                          aiAnalysisCardData[index].description;
                                    }
                                    return Column(children: [
                                      SelectableText(
                                          aiAnalysisCardData[index].title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      const Padding(
                                          padding: EdgeInsets.only(bottom: 3)),
                                      SelectableText(description,
                                          style: const TextStyle(fontSize: 16),
                                          textAlign: TextAlign.center),
                                      const Padding(
                                          padding: EdgeInsets.only(bottom: 20)),
                                    ]);
                                  })))),
                  Padding(
                      padding: const EdgeInsets.all(10),
                      child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Column(children: [
                            ElevatedButton(
                                onPressed: () async {
                                  await DatePicker.showDateTimePicker(context,
                                      showTitleActions: true,
                                      minTime: DateTime.now(),
                                      currentTime: DateTime.now(),
                                      onConfirm: (date) async {
                                    int id = await scheduleNotification(
                                        title,
                                        description,
                                        noteId,
                                        tz.TZDateTime.from(date, tz.local));
                                    await reminderStorage.write(
                                        id.toString(), date.toString());
                                    reminders
                                        .add(Reminder(id: id, datetime: date));
                                  });
                                },
                                child: const Text("Add reminder")),
                            Obx(() {
                              // Process reminder
                              List remindersToRemove = [];

                              for (Reminder reminder in reminders) {
                                if (DateTime.now()
                                    .isAfter(reminder.datetime!)) {
                                  remindersToRemove.add(reminder.id);
                                }
                              }

                              for (int reminderId in remindersToRemove) {
                                reminders.removeWhere(
                                    (element) => element.id == reminderId);
                                reminderStorage.remove(reminderId.toString());
                              }
                              noteStorage.write(
                                  "$noteId-reminders",
                                  reminders
                                      .map((element) => element.id)
                                      .toList());

                              return Tags(
                                itemCount: reminders.length, // required
                                itemBuilder: (int index) {
                                  final item = reminders[index];

                                  return ItemTags(
                                      textColor: Colors.black,
                                      color: Colors.white,
                                      index: index,
                                      title: dateFormat.format(item.datetime),
                                      removeButton: ItemTagsRemoveButton(
                                        onRemoved: () {
                                          removeNotification(
                                              reminders[index].id);
                                          reminderStorage.remove(
                                              reminders[index].id.toString());
                                          reminders.removeAt(index);
                                          return true;
                                        },
                                      ));
                                },
                              );
                            })
                          ]))),
                ],
              )),
          title: Text(title),
          appBarActions: [
            IconButton(
                onPressed: () async {
                  String? downloadDirectory = await getDownloadPath();
                  context.loaderOverlay.show();
                  File PDFPath = await exportToPdf(downloadDirectory!, title);
                  context.loaderOverlay.hide();
                  await Fluttertoast.showToast(
                      msg:
                          "PDF is stored in local storage's Download: ${basename(PDFPath.path)}",
                      toastLength: Toast.LENGTH_LONG);
                },
                icon: Icon(Icons.download)),
            IconButton(
                onPressed: () async {
                  final box = context.findRenderObject() as RenderBox?;
                  await Fluttertoast.showToast(msg: "Please wait a moment...");
                  context.loaderOverlay.show();
                  File PDFPath = await exportToPdf(
                      (await getApplicationDocumentsDirectory()).path, title);
                  context.loaderOverlay.hide();
                  await Fluttertoast.cancel();
                  await Share.shareXFiles(
                    [XFile(PDFPath.path)],
                    subject: title,
                    text: "Created by Expressive Note app: $title\n\n$description",
                    sharePositionOrigin:
                        box!.localToGlobal(Offset.zero) & box.size,
                  );

                  PDFPath.delete();
                },
                icon: const Icon(Icons.share))
          ],
        ));
  }

  Future<File> exportToPdf(String directory, String title) async {
    final generatedPdfFile = await exportToPDF(
        _quillController.document.toDelta().toJson(),
        directory,
        "$title from Expressive Note app");
    return generatedPdfFile;
  }
}
