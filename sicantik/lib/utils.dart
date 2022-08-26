import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

class CardData {
  String title;
  String description;

  CardData({
    required this.title,
    required this.description
  });
}
