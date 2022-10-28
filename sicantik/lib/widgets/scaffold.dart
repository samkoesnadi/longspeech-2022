import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';

class MyScaffold extends StatefulWidget {
  MyScaffold(
      {Key? key,
      required this.body,
      required this.title,
      this.onOpenFloatingActionButton,
      this.onCloseFloatingActionButton,
      this.appBarActions,
      this.appBarBottom,
      this.fABLocation = FloatingActionButtonLocation.endDocked,
      this.speedDialChildren = const [],
      this.bottomNavigationBarChildren = const [],
      floatingActionButtonController,
      soundLevelController})
      : super(key: key) {
    if (floatingActionButtonController == null) {
      this.floatingActionButtonController = (Icons.add).obs;
    } else {
      this.floatingActionButtonController = floatingActionButtonController;
    }

    if (soundLevelController == null) {
      this.soundLevelController = (0.0).obs;
    } else {
      this.soundLevelController = soundLevelController;
    }
  }

  Widget body;
  Widget title;
  List<Widget>? appBarActions;
  PreferredSizeWidget? appBarBottom;
  VoidCallback? onOpenFloatingActionButton;
  VoidCallback? onCloseFloatingActionButton;
  var fABLocation;
  List<SpeedDialChild> speedDialChildren;
  List<Widget> bottomNavigationBarChildren;

  late Rx<IconData> floatingActionButtonController;
  late Rx<double> soundLevelController;

  @override
  State<MyScaffold> createState() => _MyScaffold();
}

class _MyScaffold extends State<MyScaffold> {
  @override
  Widget build(BuildContext context) {
    widget.appBarActions?.add(const SizedBox.square(dimension: 10));

    return Scaffold(
        body: widget.body,
        appBar: AppBar(
          title: widget.title,
          bottom: widget.appBarBottom,
          actions: widget.appBarActions,
        ),
        floatingActionButton: SpeedDial(
          children: widget.speedDialChildren,
          icon: widget.floatingActionButtonController.value,
          activeIcon: Icons.close,
          spacing: 3,
          childPadding: const EdgeInsets.all(5),
          spaceBetweenChildren: 4,
          direction: SpeedDialDirection.up,
          switchLabelPosition: false,

          /// If true user is forced to close dial manually
          closeManually: false,

          /// If false, backgroundOverlay will not be rendered.
          renderOverlay: false,
          // overlayColor: Colors.black,
          // overlayOpacity: 0.5,
          onOpen: widget.onOpenFloatingActionButton,
          onClose: widget.onCloseFloatingActionButton,
          useRotationAnimation: true,
          heroTag: 'speed-dial-hero-tag',
          // foregroundColor: Colors.black,
          // backgroundColor: Colors.white,
          // activeForegroundColor: Colors.red,
          // activeBackgroundColor: Colors.blue,
          elevation: 8.0,
          animationCurve: Curves.elasticInOut,
          isOpenOnStart: false,
        ),
        floatingActionButtonLocation: widget.fABLocation,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Row(
              mainAxisAlignment: widget.fABLocation ==
                      FloatingActionButtonLocation.startDocked
                  ? MainAxisAlignment.end
                  : widget.fABLocation == FloatingActionButtonLocation.endDocked
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: widget.bottomNavigationBarChildren),
        ));
  }
}
