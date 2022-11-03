import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_tags/flutter_tags.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sicantik/helpers/document.dart';
import 'package:sicantik/helpers/notification.dart';
import 'package:sicantik/screens/home_screen.dart';
import 'package:sicantik/screens/new_note_screen.dart';
import 'package:sicantik/utils.dart';
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
      String datetimeStr = reminderStorage.read(reminderId.toString())!;
      DateTime datetime = DateTime.parse(datetimeStr);
      reminders.add(Reminder(id: reminderId, datetime: datetime));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<CardData> aiAnalysisCardData = [];
    aiAnalysisCardData.add(CardData(
        title: "Summary", description: noteStorage.read(noteId)["summarized"]));
    aiAnalysisCardData.add(CardData(
        title: "Detected languages",
        description: noteStorage.read("$noteId-detectedLanguages").join(", ")));
    aiAnalysisCardData.add(CardData(
        title: "Detected entities",
        description: noteStorage.read("$noteId-ners").join(", ")));

    String title = noteStorage.read(noteId)["title"];
    String description = noteStorage.read(noteId)["summarized"];

    return MyScaffold(
      backgroundColor: Colors.white,
      floatingActionButtonIcon: Icons.edit,
      speedDialOnPress: () async {
        // set the arguments
        final dynamic arguments = {"noteId": noteId};

        await Get.to(() => const NewNoteScreen(), arguments: arguments);
      },
      appBarBottom: TabBar(controller: _tabController, tabs: const [
        Tab(text: "View"),
        Tab(text: "AI-analysis"),
        Tab(text: "Reminders")
      ]),
      body: TabBarView(
        controller: _tabController,
        children: [
          // view
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              child: myQuillEditor.generateQuillEditor(readOnly: true),
            ),
          ),
          // AI-assist
          Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                  child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shrinkWrap: true,
                      itemCount: aiAnalysisCardData.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(children: [
                          Text(aiAnalysisCardData[index].title),
                          Text(aiAnalysisCardData[index].description)
                        ]);
                      }))),
          Padding(
              padding: const EdgeInsets.all(3.0),
              child: Column(children: [
                TextButton(
                    onPressed: () async {
                      await DatePicker.showDateTimePicker(context,
                          showTitleActions: true,
                          minTime: DateTime.now(),
                          currentTime: DateTime.now(), onConfirm: (date) async {
                        int id = await scheduleNotification(title, description,
                            noteId, tz.TZDateTime.from(date, tz.local));
                        await reminderStorage.write(id.toString(), date.toString());
                        reminders.add(Reminder(id: id, datetime: date));
                      });
                    },
                    child: const Text("Add reminder")),
                Obx(() {
                  // Process reminder
                  List remindersToRemove = [];

                  for (Reminder reminder in reminders) {
                    if (DateTime.now().isAfter(reminder.datetime!)) {
                      remindersToRemove.add(reminder.id);
                    }
                  }

                  for (int reminderId in remindersToRemove) {
                    reminders
                        .removeWhere((element) => element.id == reminderId);
                    reminderStorage.remove(reminderId.toString());
                  }
                  noteStorage.write("$noteId-reminders",
                      reminders.map((element) => element.id).toList());

                  return Tags(
                    itemCount: reminders.length, // required
                    itemBuilder: (int index) {
                      final item = reminders[index];

                      return ItemTags(
                          textColor: Colors.white,
                          color: Colors.blueGrey,
                          index: index,
                          title: item.datetime.toString(),
                          removeButton: ItemTagsRemoveButton(
                            onRemoved: () {
                              removeNotification(reminders[index].id);
                              reminderStorage.remove(reminders[index].id.toString());
                              reminders.removeAt(index);
                              return true;
                            },
                          ));
                    },
                  );
                })
              ])),
        ],
      ),
      title: Text(title),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.offAll(() => const HomeScreen());
          }),
    );
  }
}
