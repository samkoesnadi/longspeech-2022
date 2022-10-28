import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

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
