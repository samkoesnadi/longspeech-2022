// import 'package:flexible_scrollbar/flexible_scrollbar.dart';
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:sicantik/utils.dart';
//
// const String visibleHeadlinesKey = "visibleHeadlines";
//
// Widget scrollbarWrapper(
//     {required Widget child,
//     required ScrollController scrollController,
//     required List<CardData> cardData,
//     bool isVertical = true,
//     double thumbDragWidth = 25,
//     double thumbWidth = 20,
//     Duration animationDuration = const Duration(milliseconds: 100)}) {
//   return FlexibleScrollbar(
//       alwaysVisible: false,
//       controller: scrollController,
//       scrollLabelBuilder: (info) {
//         final bool isMoving = info.isScrolling;
//
//         GetStorage box = GetStorage();
//         List<dynamic>? visibleHeadlines = box.read(visibleHeadlinesKey);
//
//         if (isMoving && visibleHeadlines != null) {
//           visibleHeadlines.sort();
//           String scrollBarLabel = visibleHeadlines
//               .map((index) => cardData[index].title)
//               .join('\n');
//
//           return Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.black.withOpacity(0.9),
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Text(
//               scrollBarLabel,
//               style: TextStyle(
//                 fontSize: thumbDragWidth,
//                 color: Colors.white,
//               ),
//             ),
//           );
//         }
//
//         return const SizedBox.shrink();
//       },
//       barPosition: BarPosition.end,
//       child: child);
// }
