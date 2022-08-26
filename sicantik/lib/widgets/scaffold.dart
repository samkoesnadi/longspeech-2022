import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spring/spring.dart';

class MyScaffold extends StatelessWidget {
  MyScaffold(
      {Key? key,
      required this.body,
      required this.title,
      required this.onTap_floatingActionButton,
      this.appBar_actions,
      IconData default_floatingActionButton_icon = Icons.add})
      : curr_floatingActionButton_icon =
            (default_floatingActionButton_icon).obs,
        super(key: key);

  Widget body;
  Widget title;
  List<Widget>? appBar_actions;
  Function(Rx<IconData>) onTap_floatingActionButton;

  final Rx<IconData> curr_floatingActionButton_icon;
  final Rx<double> curr_sound_level = (0.0).obs;

  set sound_level(double value) {
    curr_sound_level.value = value;
  }

  set icon(IconData value) {
    curr_floatingActionButton_icon.value = value;
  }

  @override
  Widget build(BuildContext context) {
    appBar_actions?.add(const SizedBox.square(dimension: 10));

    //

    return Scaffold(
        body: body,
        appBar: AppBar(
          title: title,
          actions: appBar_actions,
        ),
        floatingActionButton: Spring.bubbleButton(
          onTap: () {
            onTap_floatingActionButton(curr_floatingActionButton_icon);
          },
          child: Obx(() => CircleAvatar(
              maxRadius: 30,
              child: Icon(
                curr_floatingActionButton_icon.value,
                size: 30,
              ))),
          animDuration: const Duration(seconds: 1),
          //def=500m mil
          bubbleStart: 0.3,
          //def=0.0
          bubbleEnd: 1.1, //def=1.1
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat);
  }
}
