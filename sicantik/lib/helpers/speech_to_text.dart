
import 'dart:io';

import 'package:appcheck/appcheck.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextHandler {
  static const int MIN_SENTENCE_WORDS = 2;
  static const int _PAUSE_FOR = 3;
  static const int _LISTEN_FOR = 30;

  List<String> sentences = [];
  static final SpeechToText _speech = SpeechToText();
  SpeechSoundLevelChange? soundLevelListener;

  static String lastError = '';
  static String lastStatus = '';
  static bool _hasSpeech = false;
  static String _currentLocaleId = '';
  static List<LocaleName> _localeNames = [];

  SpeechToTextHandler({
    this.soundLevelListener
  }) {
    assert(_hasSpeech, "Speech is not yet initialized");
  }

  List<LocaleName> get localNames => _localeNames;
  bool get hasSpeech => _hasSpeech;
  String get currentLocaleId => _currentLocaleId;
  set currentLocaleId(String val) {
    _currentLocaleId = val;
  }

  void clean_sentences() {
    sentences.clear();
  }

  void listen() {
    // Note that `listenFor` is the maximum, not the minimun, on some
    // systems recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.

    _speech.listen(
        onResult: resultListener,
        listenFor: const Duration(seconds: _LISTEN_FOR),
        pauseFor: const Duration(seconds: _PAUSE_FOR),
        partialResults: true,
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        listenMode: ListenMode.dictation
    );
  }


  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  void resultListener(SpeechRecognitionResult result) {
    if (result.finalResult) {
      store_sentence(result.recognizedWords);

      if (_speech.isListening) _speech.cancel();
      _speech.listen();
    }
  }

  void stopListening() {
    _speech.stop();
  }


  /// This initializes SpeechToText. That only has to be done
  /// once per application, though calling it again is harmless
  /// it also does nothing. The UX of the sample app ensures that
  /// it can only be called once.
  static Future<bool> initSpeechState() async {
    bool ready = true;
    if (Platform.isAndroid) {
      // needs google app to run the speech recognition
      ready &= await check_google_app();
    }

    if (!ready) return false;

    try {
      var hasSpeech = await _speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: false,
      );
      if (hasSpeech) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        _localeNames = await _speech.locales();

        var systemLocale = await _speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      _hasSpeech = hasSpeech;
    } catch (e) {
      _hasSpeech = false;
    }

    return _hasSpeech;
  }

  static void errorListener(SpeechRecognitionError error) {
    lastError = '${error.errorMsg} - ${error.permanent}';
  }

  static void statusListener(String status) {
    lastStatus = '$status';
  }

  void store_sentence(String sentence) {
    if (sentences.length == 0) {
      sentences.add(sentence);
    } else if (sentences.length == 1) {
      if (sentences.last.split(' ').length < MIN_SENTENCE_WORDS) {
        sentences.last = "${sentences.last}, $sentence";
      } else {
        sentences.add(sentence);
      }
    } else {
      if (sentence.split(' ').length < MIN_SENTENCE_WORDS) {
        sentences.last = "${sentences.last}, $sentence";
      } else {
        sentences.add(sentence);
      }
    }
  }
}

Future<bool> check_google_app() async {
  const package = "com.google.android.googlequicksearchbox";
  bool _enabled = false;
  await AppCheck.isAppEnabled(package).then(
        (enabled) => _enabled = enabled,
  );
  return _enabled;
}
