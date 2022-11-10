import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordSoundRecorder {
  static const _codec = Codec.defaultCodec;
  RxString _recorderTxt = '00:00:00'.obs;
  RxDouble _dbLevel = 0.0.obs;

  StreamSubscription? _recorderSubscription;

  void recorderSubscriptionCallback(RecordingDisposition elem) {
    var date = DateTime.fromMillisecondsSinceEpoch(elem.duration.inMilliseconds,
        isUtc: true);
    var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
    _recorderTxt.value = txt.substring(0, 8);
    _dbLevel.value = elem.decibels ?? 0;
  }

  FlutterSoundRecorder recorderModule = FlutterSoundRecorder();

  RecordSoundRecorder() {
    init();
  }

  Future<void> _initialize() async {
    await recorderModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    await initializeDateFormatting();
  }

  Future<void> openTheRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await recorderModule.openRecorder();
  }

  Future<void> init() async {
    await openTheRecorder();
    await _initialize();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  void cancelRecorderSubscriptions() {
    if (_recorderSubscription != null) {
      _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }
  }

  Future startRecorder(String filePath) async {
    try {
      // Request Microphone permission if needed
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }

      filePath = "$filePath${ext[_codec.index]}";

      await recorderModule.startRecorder(
        toFile: filePath,
        codec: _codec
      );

      recorderModule.logger.d('startRecorder');

      _recorderSubscription = recorderModule.onProgress!.listen((e) {
        recorderSubscriptionCallback(e);
      });
    } on Exception catch (err) {
      recorderModule.logger.e('startRecorder error: $err');
      stopRecorder();
      cancelRecorderSubscriptions();
    }
  }

  void stopRecorder() async {
    try {
      await recorderModule.stopRecorder();
      recorderModule.logger.d('stopRecorder');
      cancelRecorderSubscriptions();
    } on Exception catch (err) {
      recorderModule.logger.d('stopRecorder error: $err');
    }
  }

  void pauseResumeRecorder() async {
    try {
      if (recorderModule.isPaused) {
        await recorderModule.resumeRecorder();
      } else {
        await recorderModule.pauseRecorder();
        _dbLevel.value = 0;
        assert(recorderModule.isPaused);
      }
    } on Exception catch (err) {
      recorderModule.logger.e('error: $err');
    }
  }

  Widget getRecorderSection() => Obx(() {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(child: Text("Recording...")),
              Container(
                margin: EdgeInsets.only(top: 12.0, bottom: 16.0),
                child: Text(
                  _recorderTxt.value,
                  style: TextStyle(
                    fontSize: 35.0,
                    color: Colors.black,
                  ),
                ),
              ),
              LinearProgressIndicator(
                  value: 100.0 / 160.0 * _dbLevel.value / 100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  backgroundColor: Colors.red)
            ]);
      });
}

class PlayerSoundRecorder {
  static const _codec = Codec.defaultCodec;
  RxString _playerTxt = '00:00:00'.obs;
  RxDouble sliderCurrentPosition = 0.0.obs;
  RxDouble maxDuration = 1.0.obs;

  StreamSubscription? _playerSubscription;

  void playerSubscriptionCallback(PlaybackDisposition elem) {
    maxDuration.value = elem.duration.inMilliseconds.toDouble();
    if (maxDuration <= 0) maxDuration.value = 0.0;

    sliderCurrentPosition.value =
        min(elem.position.inMilliseconds.toDouble(), maxDuration.value);
    if (sliderCurrentPosition < 0.0) {
      sliderCurrentPosition.value = 0.0;
    }

    var date = DateTime.fromMillisecondsSinceEpoch(
        elem.position.inMilliseconds,
        isUtc: true);
    var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
    _playerTxt.value = txt.substring(0, 8);
  }

  FlutterSoundPlayer playerModule = FlutterSoundPlayer();

  PlayerSoundRecorder() {
    init();
  }

  Future<void> _initialize() async {
    await playerModule.closePlayer();
    await playerModule.openPlayer();
    await playerModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    await initializeDateFormatting();
  }

  Future<void> init() async {
    await _initialize();
  }

  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription!.cancel();
      _playerSubscription = null;
    }
  }

  Future<void> stopPlayer() async {
    try {
      await playerModule.stopPlayer();
      playerModule.logger.d('stopPlayer');
      if (_playerSubscription != null) {
        await _playerSubscription!.cancel();
        _playerSubscription = null;
      }
      _playerTxt.value = '00:00:00';
      sliderCurrentPosition.value = 0.0;
      maxDuration.value = 1.0;
    } on Exception catch (err) {
      playerModule.logger.d('error: $err');
    }
  }

  Future<void> startPlayer(String filePath) async {
    try {
      filePath = "$filePath${ext[_codec.index]}";

      var codec = _codec;
      print(playerModule.isStopped);
      print(playerModule.isBlank);
      print(playerModule.isOpen());
      if (playerModule.isPaused) {
        await playerModule.resumePlayer();
      }
      if (playerModule.isStopped) {
        await playerModule.startPlayer(
            fromURI: filePath,
            codec: codec,
            whenFinished: () {
              playerModule.logger.d('Play finished');
            });
      }

      _playerSubscription = playerModule.onProgress!.listen((e) {
        playerSubscriptionCallback(e);
      });
      playerModule.logger.d('<--- startPlayer');
    } on Exception catch (err) {
      playerModule.logger.e('error: $err');
    }
  }

  Future pausePlayer() async {
    try {
      if (playerModule.isPlaying) {
        await playerModule.pausePlayer();
      }
    } on Exception catch (err) {
      playerModule.logger.e('error: $err');
    }
  }

  Future<void> seekToPlayer(int milliSecs) async {
    try {
      if (playerModule.isPlaying) {
        await playerModule.seekToPlayer(Duration(milliseconds: milliSecs));
      }
    } on Exception catch (err) {
      playerModule.logger.e('error: $err');
    }
  }

  Widget getPlayerSection(String filePath) => Obx(() {
        return Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            decoration: const BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.all(Radius.circular(16.0)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4.0,
                  offset: Offset(0.0, 4.0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      _playerTxt.value,
                      style: TextStyle(fontSize: 16),
                    ),
                    IconButton(
                        padding: EdgeInsets.only(left: 8),
                        onPressed: () => startPlayer(filePath),
                        icon: Icon(Icons.play_arrow)),
                    IconButton(
                        padding: EdgeInsets.only(left: 8),
                        onPressed: pausePlayer,
                        icon: Icon(Icons.pause)),
                    IconButton(
                      padding: EdgeInsets.only(left: 8),
                      onPressed: stopPlayer,
                      icon: Icon(Icons.stop),
                    ),
                    Expanded(
                        child: Slider(
                            value: min(
                                sliderCurrentPosition.value, maxDuration.value),
                            min: 0.0,
                            max: maxDuration.value,
                            onChanged: (value) async {
                              await seekToPlayer(value.toInt());
                            },
                            divisions:
                                maxDuration == 0.0 ? 1 : maxDuration.toInt())),
                  ],
                ),
              ],
            ));
      });
}
