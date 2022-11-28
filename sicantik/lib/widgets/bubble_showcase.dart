import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:flutter/material.dart';
import 'package:sicantik/theme_data.dart';
import 'package:sicantik/widgets/speech_bubble.dart';

const doNotReopenOnClose = true;
int bubbleShowcaseVersion = 1;
Color bubbleColor = grey.shade500;
const textColor = Colors.white;

class BubbleShowcaseHomeScreenWidget extends StatelessWidget {
  GlobalKey buttonKey;
  Widget child;

  BubbleShowcaseHomeScreenWidget(
      {required this.buttonKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return BubbleShowcase(
        bubbleShowcaseId: 'homeScreen',
        bubbleShowcaseVersion: bubbleShowcaseVersion,
        doNotReopenOnClose: doNotReopenOnClose,
        bubbleSlides: [
          AbsoluteBubbleSlide(
            positionCalculator: (size) =>
                Position(left: 0, top: 0, right: 0, bottom: size.height),
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.left,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                    nipLocation: NipLocation.LEFT,
                    color: bubbleColor,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                          'My name is Samuel Matthew, the Expressive Notes app author 👨‍🔧 Welcome to the app!\n\n'
                          'I am now going to give you a quick walk through the app 😄\n\n'
                          'We will learn how to use this App to allow your productivity and creativity to shine! And yes, your note will be analyzed by AI for key information 😉 It runs on your device, so all data of yours is kept safely in your device.\n\n\n'
                          'With love, Samuel.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center),
                    ),
                  )),
            ),
          ),
          // AbsoluteBubbleSlide(
          //   positionCalculator: (size) =>
          //       Position(left: 0, top: 0, right: 0, bottom: size.height),
          //   child: RelativeBubbleSlideChild(
          //     direction: AxisDirection.left,
          //     widget: Padding(
          //         padding: const EdgeInsets.all(10),
          //         child: SpeechBubble(
          //           nipLocation: NipLocation.LEFT,
          //           color: bubbleColor,
          //           child: Padding(
          //             padding: const EdgeInsets.all(10),
          //             child: Column(
          //               children: [
          //                 Text('First off, I give you one example use case:',
          //                     style: TextStyle(color: Colors.white),
          //                     textAlign: TextAlign.center),
          //                 Padding(padding: EdgeInsets.only(bottom: 3)),
          //                 Image.asset("assets/feature.png")
          //               ],
          //             ),
          //           ),
          //         )),
          //   ),
          // ),
          RelativeBubbleSlide(
            widgetKey: buttonKey,
            highlightPadding: 4,
            // passThroughMode: PassthroughMode.INSIDE_WITH_NOTIFICATION,
            shape: const Circle(spreadRadius: 15),
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.right,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                      nipLocation: NipLocation.RIGHT,
                      color: bubbleColor,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Text('Click here to add new note',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center),
                      ))),
            ),
          ),
        ],
        child: child);
  }
}

class BubbleShowcaseNewNoteWidget extends StatelessWidget {
  GlobalKey toolbarKey;
  GlobalKey appBarKey;
  Widget child;

  BubbleShowcaseNewNoteWidget(
      {required this.toolbarKey, required this.appBarKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return BubbleShowcase(
        bubbleShowcaseId: 'newNote',
        bubbleShowcaseVersion: bubbleShowcaseVersion,
        doNotReopenOnClose: doNotReopenOnClose,
        bubbleSlides: [
          RelativeBubbleSlide(
            widgetKey: toolbarKey,
            highlightPadding: 2,
            // passThroughMode: PassthroughMode.INSIDE_WITH_NOTIFICATION,
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.up,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                      nipLocation: NipLocation.BOTTOM,
                      color: bubbleColor,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Text(
                            "Here are the tools for your creativity, whether it is changing font, color, size, or even creating list, checkboxes, or hyperlink. I got you covered",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center),
                      ))),
            ),
          ),
          RelativeBubbleSlide(
            widgetKey: toolbarKey,
            highlightPadding: 2,
            // passThroughMode: PassthroughMode.INSIDE_WITH_NOTIFICATION,
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.up,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                      nipLocation: NipLocation.BOTTOM,
                      color: bubbleColor,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Text(
                            "AI will analyze your note and find key information:\n"
                            "Try taking a photo with the camera button, and the AI will detect the objects in it. "
                            "These objects detections will be considered as key information for AI analysis",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center),
                      ))),
            ),
          ),
          RelativeBubbleSlide(
            widgetKey: toolbarKey,
            highlightPadding: 2,
            // passThroughMode: PassthroughMode.INSIDE_WITH_NOTIFICATION,
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.up,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                      nipLocation: NipLocation.BOTTOM,
                      color: bubbleColor,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Text(
                            "Try out speech-to-text to write with your voice\n"
                            "Or you want to simply record voices of any presentation or lecture, maybe?",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center),
                      ))),
            ),
          ),
          RelativeBubbleSlide(
            widgetKey: toolbarKey,
            highlightPadding: 2,
            // passThroughMode: PassthroughMode.INSIDE_WITH_NOTIFICATION,
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.up,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                      nipLocation: NipLocation.BOTTOM,
                      color: bubbleColor,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Text(
                          "You can even write with your finger on screen, and "
                          "the AI will tell you what you write. "
                          "You can also save this handwriting in the "
                          "image gallery by clicking on the image -> Save",
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ))),
            ),
          ),
          RelativeBubbleSlide(
            widgetKey: appBarKey,
            highlightPadding: 2,
            // passThroughMode: PassthroughMode.INSIDE_WITH_NOTIFICATION,
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.down,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                      nipLocation: NipLocation.TOP_RIGHT,
                      color: bubbleColor,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Text(
                            "Click on the star button to mark the note as favorite. "
                            "It will be shown on the top of the list of notes.",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center),
                      ))),
            ),
          ),
          AbsoluteBubbleSlide(
            positionCalculator: (size) =>
                Position(left: 0, top: 0, right: 0, bottom: size.height),
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.left,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                      nipLocation: NipLocation.LEFT,
                      color: bubbleColor,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                            "Have fun and good luck with your productivity 😄 "
                            "At any time when you want to make notes or agenda, simply open the app and add a note. Quick tips: You can also add the app to home screen for quick access",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center),
                      ))),
            ),
          )
        ],
        child: child);
  }
}

class BubbleShowcaseViewNoteWidget extends StatelessWidget {
  GlobalKey tabBarGlobalKey;
  GlobalKey appBarGlobalKey;
  Widget child;

  BubbleShowcaseViewNoteWidget(
      {required this.tabBarGlobalKey,
      required this.appBarGlobalKey,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return BubbleShowcase(
        bubbleShowcaseId: 'viewNote',
        bubbleShowcaseVersion: bubbleShowcaseVersion,
        doNotReopenOnClose: doNotReopenOnClose,
        bubbleSlides: [
          RelativeBubbleSlide(
            widgetKey: tabBarGlobalKey,
            highlightPadding: 2,
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.down,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                    nipLocation: NipLocation.TOP_LEFT,
                    color: bubbleColor,
                    child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Text(
                            'You can view the note without editing here',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center)),
                  )),
            ),
          ),
          RelativeBubbleSlide(
            widgetKey: tabBarGlobalKey,
            highlightPadding: 2,
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.down,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                    nipLocation: NipLocation.TOP,
                    color: bubbleColor,
                    child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                            'All AI analysis is here, starting from the detected keywords until summarization of the note',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center)),
                  )),
            ),
          ),
          RelativeBubbleSlide(
            widgetKey: tabBarGlobalKey,
            highlightPadding: 2,
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.down,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                    nipLocation: NipLocation.TOP_RIGHT,
                    color: bubbleColor,
                    child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                            'Sometimes we want to be reminded of our own note in a specific time in the future, let it be an agenda or a simple self-note. You can create a scheduled reminder here',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center)),
                  )),
            ),
          ),
          RelativeBubbleSlide(
            widgetKey: appBarGlobalKey,
            highlightPadding: 2,
            child: RelativeBubbleSlideChild(
              direction: AxisDirection.down,
              widget: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SpeechBubble(
                    nipLocation: NipLocation.TOP_RIGHT,
                    color: bubbleColor,
                    child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                            'You can also share the note in PDF to social media or E-mail. Sharing is caring, am I right?',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center)),
                  )),
            ),
          ),
        ],
        child: child);
  }
}
