import 'dart:async';

import 'package:get_storage/get_storage.dart';
import 'package:sicantik/utils.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

// class SpeechToTextDummy {
//   String text;
//   int period;
//   late Timer _timer;
//
//   SpeechToTextDummy({this.text = "hello", this.period = 2});
//
//   Future listen(
//       {SpeechResultListener? onResult,
//       Duration? listenFor,
//       Duration? pauseFor,
//       String? localeId,
//       SpeechSoundLevelChange? onSoundLevelChange,
//       cancelOnError = false,
//       partialResults = true,
//       onDevice = false,
//       ListenMode listenMode = ListenMode.confirmation,
//       sampleRate = 0}) async {
//     _timer =
//         Timer.periodic(Duration(seconds: period), (Timer t) => print('hi!'));
//   }
//
//   void stop() {
//     _timer.cancel();
//   }
//
//   Future<bool> initialize(
//       {SpeechErrorListener? onError,
//         SpeechStatusListener? onStatus,
//         debugLogging = false,
//         Duration? finalTimeout,
//         List<dynamic>? options}) async {
//       return true;
//   }
//
//   // Future<List<LocaleName>> locales() async {
//   //   return
//   // }
//
//   Future<LocaleName?> systemLocale() async {
//
//   }
// }

class SpeechToTextHandler {
  static const int minSentenceWords = 2;
  static const int pauseFor = 30;
  static const int listenFor = 30;

  Function(double)? soundLevelListener;
  Function(String, String, int) partialResultListener;
  Function(String) errorListener;

  bool _listenLoop = true;

  static final SpeechToText _speech = SpeechToText();
  static String _currentLocaleId = '';  // this is to be taken outside of class.
  String fullText = "";  // this is to be taken outside of class.
  static List<LocaleName> localeNames = [];  // this is to be taken outside of class.

  int lastTextCount = 0;

  SpeechToTextHandler(
      {this.soundLevelListener,
      required this.partialResultListener,
      required this.errorListener});

  List<LocaleName> get localNames => localeNames;

  Future<void> _listen() async {
    // Note that `listenFor` is the maximum, not the minimun, on some
    // systems recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.
    await _speech.listen(
        onResult: resultListener,
        listenFor: const Duration(seconds: listenFor),
        pauseFor: const Duration(seconds: pauseFor),
        partialResults: true,
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: false,
        listenMode: ListenMode.dictation);
  }

  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  void resultListener(SpeechRecognitionResult result) {
    if (result.recognizedWords.isNotEmpty) {
      partialResultListener(result.recognizedWords, this.fullText, this.lastTextCount);

      if (result.finalResult) {
        storeSentence(result.recognizedWords);
        _listen();
      }
    }
  }

  void stopListening() {
    _listenLoop = false;
    _speech.stop();
  }

  /// This initializes SpeechToText. That only has to be done
  /// once per application, though calling it again is harmless
  /// it also does nothing. The UX of the sample app ensures that
  /// it can only be called once.
  Future<bool> initSpeechState() async {
    bool ready = true;

    try {
      var hasSpeech = await _speech.initialize(
        onError: _errorListener,
        onStatus: _statusListener,
        debugLogging: true,
        options: [SpeechToText.androidIntentLookup],
      );
      if (hasSpeech && localeNames.isEmpty) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        localeNames = await _speech.locales();
        var systemLocale = await _speech.systemLocale();

        GetStorage commonStorage = GetStorage();
        _currentLocaleId = commonStorage.read("speechToTextLanguage") ?? systemLocale?.localeId ?? '';
      }
      ready = hasSpeech;
    } catch (e) {
      logger.e(e);
      ready = false;
    }

    return ready;
  }

  static String get currentLocaleId => _currentLocaleId;
  static set currentLocaleId(String value) {
    _currentLocaleId = value;
    GetStorage commonStorage = GetStorage();
    commonStorage.write("speechToTextLanguage", value);
  }

  void _errorListener(SpeechRecognitionError error) {
    if (error.errorMsg == "error_speech_timeout" ||
        error.errorMsg == "error_no_match" ||
        error.errorMsg == "error_busy") {
      return;
    } else {
      _listenLoop = false;
    }

    errorListener(error.errorMsg);
  }

  Future _statusListener(String status) async {
    if (status == "done") {
      if (_listenLoop) {
        await _listen();
      }
    }
  }

  void listen() {
    _listenLoop = true;
    _listen();
  }

  void storeSentence(String sentence) {
    final combined = combineSentences(fullText, lastTextCount, sentence);
    fullText = combined[0];
    lastTextCount = combined[1];
  }

  static List<dynamic> combineSentences(String fullText, int lastTextCount, String sentence) {
    int sentenceLength = sentence.split(" ").length;
    if (fullText.isEmpty) {
      fullText = sentence;
      lastTextCount = sentenceLength;
    } else {
      String separator = ".";
      if (lastTextCount <= minSentenceWords) {
        separator = ",";
        lastTextCount += sentenceLength;
      } else {
        lastTextCount = sentenceLength;
      }
      fullText = "$fullText$separator $sentence";
    }

    return [fullText, lastTextCount];
  }
}
