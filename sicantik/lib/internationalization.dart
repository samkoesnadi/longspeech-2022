/// Set all standardized texts

import 'package:get/get.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'title': 'ElegantNote',
      "untitled": "Untitled",
      "viewNote": "View",
      "AINote": "AI-assist"
    },
  };
}
