import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

class HomeScreenState extends State<HomeScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // TODO: you can replace the sample list
    List<CardData> sample_card_data_list = [
      CardData(
          title: '01',
          description:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaasdf'),
      CardData(title: '02', description: 'asdf'),
      CardData(title: '03', description: 'asdf'),
      CardData(title: '04', description: 'asdf'),
      CardData(title: '05', description: 'asdf'),
      CardData(title: '0', description: 'asdf'),
      CardData(title: '0', description: 'asdf'),
      CardData(title: '0', description: 'asdf'),
      CardData(title: '0', description: 'asdf'),
      CardData(title: '0', description: 'asdf'),
      CardData(title: '0', description: 'asdf'),
      CardData(title: '0', description: 'asdf'),
      CardData(title: '0', description: 'asdf')
    ];
    return MyScaffold(
        body: scrollbar_wrapper(
            child: generate_list_view(
                scrollController: scrollController,
                card_data_list: sample_card_data_list),
            scrollController: scrollController,
            card_data_list: sample_card_data_list),
        title: Text("title".tr),
        appBar_actions: [
          InkWell(
              onTap: () {}, child: const Icon(Icons.account_circle_rounded)),
        ],
        onTap_floatingActionButton: (curr_floatingActionButton_icon) {
          Get.to(() => NewNoteScreen());
        }
    );
  }
}
