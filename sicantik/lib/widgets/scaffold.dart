import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sicantik/theme_data.dart';

class MyScaffold extends StatelessWidget {
  MyScaffold(
      {Key? key,
      required this.body,
      required this.title,
      required this.onTap_floatingActionButton,
      this.appBar_actions,
      floating_action_button_controller,
      sound_level_controller})
      : super(key: key) {
    if (floating_action_button_controller == null) {
      this.floating_action_button_controller = (Icons.add).obs;
    } else {
      this.floating_action_button_controller = floating_action_button_controller;
    }

    if (sound_level_controller == null) {
      this.sound_level_controller = (0.0).obs;
    } else {
      this.sound_level_controller = sound_level_controller;
    }
  }

  Widget body;
  Widget title;
  List<Widget>? appBar_actions;
  Function() onTap_floatingActionButton;

  late Rx<IconData> floating_action_button_controller;
  late Rx<double> sound_level_controller;

  @override
  Widget build(BuildContext context) {
    appBar_actions?.add(const SizedBox.square(dimension: 10));

    return Scaffold(
        body: body,
        appBar: AppBar(
          title: title,
          actions: appBar_actions,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            onTap_floatingActionButton();
          },
          elevation: 0,
          child: Obx(() => Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(100),
                ),
                boxShadow: [
                  BoxShadow(
                      color: theme_data.primaryColorDark,
                      spreadRadius: sound_level_controller.value,
                      blurRadius: sound_level_controller.value),
                ],
              ),
              child: CircleAvatar(
                  radius: 30,
                  child: Icon(
                    floating_action_button_controller.value,
                  )))),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat);
  }
}
