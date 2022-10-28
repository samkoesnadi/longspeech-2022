import 'dart:async';
import 'dart:io';

import 'package:appcheck/appcheck.dart';
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

  Function(double) soundLevelListener;
  Function(String) partialResultListener;
  Function(String) fullResultListener;
  Function(String) errorListener;

  bool _listenLoop = false;

  static final SpeechToText _speech = SpeechToText();
  static String currentLocaleId = '';
  static String fullText = "";
  static List<LocaleName> localeNames = [];

  int lastTextCount = 0;

  SpeechToTextHandler(
      {required this.soundLevelListener,
      required this.partialResultListener,
      required this.fullResultListener,
      required this.errorListener});

  List<LocaleName> get localNames => localeNames;

  void _soundLevelListener(double level) {
    soundLevelListener(level);
  }

  Future<void> _listen() async {
    bool available = await initSpeechState();

    if (!available) {
      errorListener("Speech recognizer cannot be initiated");
    }

    // Note that `listenFor` is the maximum, not the minimun, on some
    // systems recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.
    await _speech.listen(
        onResult: resultListener,
        listenFor: const Duration(seconds: listenFor),
        pauseFor: const Duration(seconds: pauseFor),
        partialResults: true,
        localeId: currentLocaleId,
        onSoundLevelChange: _soundLevelListener,
        cancelOnError: false,
        listenMode: ListenMode.dictation);
  }

  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  void resultListener(SpeechRecognitionResult result) {
    if (result.recognizedWords.isNotEmpty) {
      partialResultListener(result.recognizedWords);

      if (result.finalResult) {
        storeSentence(result.recognizedWords);
        fullResultListener(fullText);
      }
    }
  }

  void stopListening() {
    _listenLoop = false;
    _speech.stop();
  }

  Future<bool> initSpeechState() {
    return preInitSpeechState(
        errorListener: _errorListener, statusListener: _statusListener);
  }

  /// This initializes SpeechToText. That only has to be done
  /// once per application, though calling it again is harmless
  /// it also does nothing. The UX of the sample app ensures that
  /// it can only be called once.
  static Future<bool> preInitSpeechState(
      {SpeechErrorListener? errorListener,
      SpeechStatusListener? statusListener}) async {
    bool ready = true;

    try {
      var hasSpeech = await _speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: true,
        options: [SpeechToText.androidIntentLookup],
      );
      if (hasSpeech && localeNames.isEmpty) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        localeNames = await _speech.locales();
        var systemLocale = await _speech.systemLocale();

        currentLocaleId = systemLocale?.localeId ?? '';
      }
      ready = hasSpeech;
    } catch (e) {
      logger.e(e);
      ready = false;
    }

    return ready;
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
  }
}