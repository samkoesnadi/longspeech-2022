import 'dart:io';

import 'package:appcheck/appcheck.dart';
import 'package:get/utils.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextHandler {
  static const int MIN_SENTENCE_WORDS = 2;
  static const int _PAUSE_FOR = 30;
  static const int _LISTEN_FOR = 30;

  late SpeechToText _speech;
  Function(double level) soundLevelListener;
  Function(String partial_text) partialResultListener;
  Function(String full_text) fullResultListener;
  Function(String error_text) errorListener;

  bool _hasSpeech = false;
  bool _listen_loop = false;
  String _currentLocaleId = '';
  String full_text = "";
  int last_text_count = 0;
  List<LocaleName> _localeNames = [];

  SpeechToTextHandler(
      {required this.soundLevelListener,
      required this.partialResultListener,
      required this.fullResultListener,
      required this.errorListener});

  List<LocaleName> get localNames => _localeNames;

  bool get hasSpeech => _hasSpeech;

  String get currentLocaleId => _currentLocaleId;

  set currentLocaleId(String val) {
    _currentLocaleId = val;
  }

  void _soundLevelListener(double level) {
    this.soundLevelListener(level);
  }

  Future<void> _listen() async {
    bool _available = await initSpeechState();

    if (!_available) {
      errorListener("Speech recognizer cannot be initiated");
    }

    // Note that `listenFor` is the maximum, not the minimun, on some
    // systems recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.
    await _speech.listen(
        onResult: resultListener,
        listenFor: const Duration(seconds: _LISTEN_FOR),
        pauseFor: const Duration(seconds: _PAUSE_FOR),
        partialResults: true,
        localeId: _currentLocaleId,
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
        store_sentence(result.recognizedWords);
        fullResultListener(full_text);
      }
    }
  }

  void stopListening() {
    _listen_loop = false;
    _speech.stop();
  }

  /// This initializes SpeechToText. That only has to be done
  /// once per application, though calling it again is harmless
  /// it also does nothing. The UX of the sample app ensures that
  /// it can only be called once.
  Future<bool> initSpeechState() async {
    bool ready = true;
    if (Platform.isAndroid) {
      // needs google app to run the speech recognition
      ready &= await check_google_app();
    }

    if (!ready) return false;

    try {
      _speech = SpeechToText();
      var hasSpeech = await _speech.initialize(
        onError: _errorListener,
        onStatus: _statusListener,
        debugLogging: true,
        options: [SpeechToText.androidIntentLookup],
      );
      if (hasSpeech && _localeNames.isEmpty) {
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

  void _errorListener(SpeechRecognitionError error) {
    if (
      error.errorMsg == "error_speech_timeout"
      || error.errorMsg == "error_no_match"
      || error.errorMsg == "error_busy"
    ) {
      return;
    } else {
      _listen_loop = false;
    }

    errorListener(error.errorMsg);
  }

  Future _statusListener(String status) async {
    if (status == "done") {
      if (_listen_loop) {
        await _listen();
      }
    }
  }

  void listen() {
    _listen_loop = true;
    _listen();
  }

  void store_sentence(String sentence) {
    int sentence_length = sentence.split(" ").length;
    if (full_text.isEmpty) {
      full_text = sentence;
      last_text_count = sentence_length;
    } else {
      String separator = ".";
      if (last_text_count <= MIN_SENTENCE_WORDS) {
        separator = ",";
        last_text_count += sentence_length;
      } else {
        last_text_count = sentence_length;
      }
      full_text = "$full_text$separator $sentence";
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
