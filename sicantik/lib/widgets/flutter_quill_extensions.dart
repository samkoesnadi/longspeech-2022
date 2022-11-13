library flutter_quill_extensions;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/extensions.dart' as base;
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill/translations.dart';
import 'package:flutter_quill_extensions/embeds/builders.dart';
import 'package:flutter_quill_extensions/embeds/embed_types.dart';
import 'package:flutter_quill_extensions/embeds/toolbar/camera_button.dart';
import 'package:flutter_quill_extensions/embeds/toolbar/formula_button.dart';
import 'package:flutter_quill_extensions/embeds/toolbar/image_button.dart';
import 'package:flutter_quill_extensions/embeds/toolbar/video_button.dart';
import 'package:flutter_quill_extensions/embeds/utils.dart';
import 'package:flutter_quill_extensions/embeds/widgets/image.dart';
import 'package:flutter_quill_extensions/embeds/widgets/image_resizer.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:sicantik/widgets/sound.dart';
import 'package:tuple/tuple.dart';

Widget _menuOptionsForReadonlyImage(
    BuildContext context, String imageUrl, Widget image) {
  return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              final saveOption = _SimpleDialogItem(
                icon: Icons.save,
                color: Colors.greenAccent,
                text: 'Save'.i18n,
                onPressed: () {
                  imageUrl = appendFileExtensionToImageUrl(imageUrl);
                  GallerySaver.saveImage(imageUrl).then((_) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Saved'.i18n)));
                    Navigator.pop(context);
                  });
                },
              );
              final zoomOption = _SimpleDialogItem(
                icon: Icons.zoom_in,
                color: Colors.cyanAccent,
                text: 'Zoom'.i18n,
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ImageTapWrapper(imageUrl: imageUrl)));
                },
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
                child: SimpleDialog(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    children: [saveOption, zoomOption]),
              );
            });
      },
      child: image);
}

class _SimpleDialogItem extends StatelessWidget {
  const _SimpleDialogItem(
      {required this.icon,
      required this.color,
      required this.text,
      required this.onPressed,
      Key? key})
      : super(key: key);

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 36, color: color),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child:
                Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class MyImageEmbedBuilder implements EmbedBuilder {
  void Function(String)? onRemove;
  Map? imageArguments;

  MyImageEmbedBuilder({this.onRemove, this.imageArguments});

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    base.Embed node,
    bool readOnly,
  ) {
    assert(!kIsWeb, 'Please provide image EmbedBuilder for Web');

    var image;
    final imageUrl = standardizeImageUrl(node.value.data);

    List<String> detectedObjects = [];
    bool showDetectedObjects = false;

    if (imageArguments != null) {
      if (imageArguments!.containsKey(imageUrl)) {
        detectedObjects = imageArguments![imageUrl]!.cast<String>();
        showDetectedObjects = true;
      }
    }
    if (detectedObjects.isEmpty) {
      detectedObjects = ["none"];
    }

    Tuple2<double?, double?>? _widthHeight;
    final style = node.style.attributes['style'];
    if (base.isMobile() && style != null) {
      final _attrs = base.parseKeyValuePairs(style.value.toString(), {
        Attribute.mobileWidth,
        Attribute.mobileHeight,
        Attribute.mobileMargin,
        Attribute.mobileAlignment
      });
      if (_attrs.isNotEmpty) {
        assert(
            _attrs[Attribute.mobileWidth] != null &&
                _attrs[Attribute.mobileHeight] != null,
            'mobileWidth and mobileHeight must be specified');
        final w = double.parse(_attrs[Attribute.mobileWidth]!);
        final h = double.parse(_attrs[Attribute.mobileHeight]!);
        _widthHeight = Tuple2(w, h);
        final m = _attrs[Attribute.mobileMargin] == null
            ? 0.0
            : double.parse(_attrs[Attribute.mobileMargin]!);
        final a = base.getAlignment(_attrs[Attribute.mobileAlignment]);
        image = Padding(
            padding: EdgeInsets.all(m),
            child: imageByUrl(imageUrl, width: w, height: h, alignment: a));
      }
    }

    if (_widthHeight == null) {
      image = imageByUrl(imageUrl);
      _widthHeight = Tuple2((image as Image).width, image.height);
    }

    Widget textWidget = const SizedBox.shrink();
    if (showDetectedObjects) {
      textWidget = Align(
        alignment: Alignment.center,
        child: SelectableText(
          "Detected:\n${detectedObjects.join(", ")}\n",
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!readOnly && base.isMobile()) {
      return GestureDetector(
          onTap: () {
            showDialog(
                context: context,
                builder: (context) {
                  final saveOption = _SimpleDialogItem(
                    icon: Icons.save,
                    color: Colors.greenAccent,
                    text: 'Save'.i18n,
                    onPressed: () {
                      String _imageUrl = appendFileExtensionToImageUrl(imageUrl);
                      GallerySaver.saveImage(_imageUrl).then((_) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Saved'.i18n)));
                        Navigator.pop(context);
                      });
                    },
                  );
                  final zoomOption = _SimpleDialogItem(
                    icon: Icons.zoom_in,
                    color: Colors.cyanAccent,
                    text: 'Zoom'.i18n,
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ImageTapWrapper(imageUrl: imageUrl)));
                    },
                  );
                  final resizeOption = _SimpleDialogItem(
                    icon: Icons.settings_outlined,
                    color: Colors.lightBlueAccent,
                    text: 'Resize'.i18n,
                    onPressed: () {
                      Navigator.pop(context);
                      showCupertinoModalPopup<void>(
                          context: context,
                          builder: (context) {
                            final _screenSize = MediaQuery.of(context).size;
                            return ImageResizer(
                                onImageResize: (w, h) {
                                  final res = getEmbedNode(
                                      controller, controller.selection.start);
                                  final attr = base.replaceStyleString(
                                      getImageStyleString(controller), w, h);
                                  controller
                                    ..skipRequestKeyboard = true
                                    ..formatText(
                                        res.item1, 1, StyleAttribute(attr));
                                },
                                imageWidth: _widthHeight?.item1,
                                imageHeight: _widthHeight?.item2,
                                maxWidth: _screenSize.width,
                                maxHeight: _screenSize.height);
                          });
                    },
                  );
                  final copyOption = _SimpleDialogItem(
                    icon: Icons.copy_all_outlined,
                    color: Colors.cyanAccent,
                    text: 'Copy'.i18n,
                    onPressed: () {
                      final imageNode =
                          getEmbedNode(controller, controller.selection.start)
                              .item2;
                      final imageUrl = imageNode.value.data;
                      controller.copiedImageUrl =
                          Tuple2(imageUrl, getImageStyleString(controller));
                      Navigator.pop(context);
                    },
                  );
                  final removeOption = _SimpleDialogItem(
                    icon: Icons.delete_forever_outlined,
                    color: Colors.red.shade200,
                    text: 'Remove'.i18n,
                    onPressed: () async {
                      final embedNode =
                          getEmbedNode(controller, controller.selection.start);
                      final offset = embedNode.item1;
                      controller.replaceText(offset, 1, '',
                          TextSelection.collapsed(offset: offset));

                      if (onRemove != null) {
                        final imageNode = embedNode.item2;
                        final imageUrl = imageNode.value.data;

                        onRemove!(imageUrl);
                      }
                      Navigator.pop(context);
                    },
                  );
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
                    child: SimpleDialog(
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        children: [saveOption, zoomOption, resizeOption, copyOption, removeOption]),
                  );
                });
          },
          child: Column(
            children: [image, textWidget],
          ));
    }

    if (!readOnly || !base.isMobile() || isImageBase64(imageUrl)) {
      return image;
    }

    // We provide option menu for mobile platform excluding base64 image
    return _menuOptionsForReadonlyImage(
        context,
        imageUrl,
        Column(
          children: [image, textWidget],
        ));
  }

  @override
  String get key => BlockEmbed.imageType;
}

class FlutterQuillEmbeds {
  static List<EmbedBuilder> builders(
          {void Function(GlobalKey videoContainerKey)? onVideoInit,
          void Function(String)? onImageRemove,
          Map? imageArguments}) =>
      [
        MyImageEmbedBuilder(
            onRemove: onImageRemove, imageArguments: imageArguments),
        VideoEmbedBuilder(onVideoInit: onVideoInit),
        FormulaEmbedBuilder(),
      ];

  static List<EmbedButtonBuilder> buttons({
    bool showImageButton = true,
    bool showVideoButton = true,
    bool showCameraButton = true,
    bool showFormulaButton = false,
    OnImagePickCallback? onImagePickCallback,
    OnVideoPickCallback? onVideoPickCallback,
    MediaPickSettingSelector? mediaPickSettingSelector,
    MediaPickSettingSelector? cameraPickSettingSelector,
    FilePickImpl? filePickImpl,
    WebImagePickImpl? webImagePickImpl,
    WebVideoPickImpl? webVideoPickImpl,
  }) {
    return [
      if (showImageButton)
        (controller, toolbarIconSize, iconTheme, dialogTheme) {
          QuillIconTheme? _iconTheme = QuillIconTheme(
              iconSelectedColor: iconTheme?.iconSelectedColor,
              iconUnselectedColor: iconTheme?.iconUnselectedColor,
              iconSelectedFillColor: iconTheme?.iconSelectedFillColor,
              iconUnselectedFillColor: iconTheme?.iconUnselectedFillColor,
              disabledIconColor: iconTheme?.disabledIconColor,
              disabledIconFillColor: iconTheme?.disabledIconFillColor,
              borderRadius: iconTheme?.borderRadius);
          return ImageButton(
            icon: Icons.image,
            iconSize: toolbarIconSize,
            controller: controller,
            onImagePickCallback: onImagePickCallback,
            filePickImpl: filePickImpl,
            webImagePickImpl: webImagePickImpl,
            mediaPickSettingSelector: mediaPickSettingSelector,
            iconTheme: _iconTheme,
            dialogTheme: dialogTheme,
          );
        },
      if (showVideoButton)
        (controller, toolbarIconSize, iconTheme, dialogTheme) => VideoButton(
              icon: Icons.movie_creation,
              iconSize: toolbarIconSize,
              controller: controller,
              onVideoPickCallback: onVideoPickCallback,
              filePickImpl: filePickImpl,
              webVideoPickImpl: webImagePickImpl,
              mediaPickSettingSelector: mediaPickSettingSelector,
              iconTheme: iconTheme,
              dialogTheme: dialogTheme,
            ),
      if ((onImagePickCallback != null || onVideoPickCallback != null) &&
          showCameraButton)
        (controller, toolbarIconSize, iconTheme, dialogTheme) {
          QuillIconTheme? _iconTheme = QuillIconTheme(
              iconSelectedColor: iconTheme?.iconSelectedColor,
              iconUnselectedColor: iconTheme?.iconUnselectedColor,
              iconSelectedFillColor: iconTheme?.iconSelectedFillColor,
              iconUnselectedFillColor: iconTheme?.iconUnselectedFillColor,
              disabledIconColor: iconTheme?.disabledIconColor,
              disabledIconFillColor: iconTheme?.disabledIconFillColor,
              borderRadius: iconTheme?.borderRadius);
          return CameraButton(
            icon: Icons.photo_camera,
            iconSize: toolbarIconSize,
            controller: controller,
            onImagePickCallback: onImagePickCallback,
            onVideoPickCallback: onVideoPickCallback,
            filePickImpl: filePickImpl,
            webImagePickImpl: webImagePickImpl,
            webVideoPickImpl: webVideoPickImpl,
            cameraPickSettingSelector: cameraPickSettingSelector,
            iconTheme: _iconTheme,
          );
        },
      if (showFormulaButton)
        (controller, toolbarIconSize, iconTheme, dialogTheme) => FormulaButton(
              icon: Icons.functions,
              iconSize: toolbarIconSize,
              controller: controller,
              onImagePickCallback: onImagePickCallback,
              filePickImpl: filePickImpl,
              webImagePickImpl: webImagePickImpl,
              mediaPickSettingSelector: mediaPickSettingSelector,
              iconTheme: iconTheme,
              dialogTheme: dialogTheme,
            )
    ];
  }
}

var cameraPickSettingSelector = (context) => showDialog<MediaPickSetting>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(
                Icons.camera,
                color: Colors.orangeAccent,
              ),
              label: Text(
                'Camera'.i18n,
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.pop(ctx, MediaPickSetting.Camera),
            ),
            TextButton.icon(
              icon: const Icon(
                Icons.video_call,
                color: Colors.cyanAccent,
              ),
              label: Text('Video'.i18n, style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(ctx, MediaPickSetting.Video),
            )
          ],
        ),
      ),
    );

var speechRecordPickSettingSelector = (context) => showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(
                Icons.camera,
                color: Colors.orangeAccent,
              ),
              label: Text(
                'Record audio',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.pop(ctx, "RecordAudio"),
            ),
            TextButton.icon(
              icon: const Icon(
                Icons.video_call,
                color: Colors.cyanAccent,
              ),
              label: Text('Speech-to-text',
                  style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(ctx, "SpeechRecognition"),
            )
          ],
        ),
      ),
    );

var mediaPickSettingSelector = (context) => showDialog<MediaPickSetting>(
    context: context,
    builder: (ctx) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(
                  Icons.collections,
                  color: Colors.orangeAccent,
                ),
                label:
                    Text('Gallery'.i18n, style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(ctx, MediaPickSetting.Gallery),
              ),
              TextButton.icon(
                icon: const Icon(
                  Icons.link,
                  color: Colors.cyanAccent,
                ),
                label: Text('Link'.i18n, style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(ctx, MediaPickSetting.Link),
              )
            ],
          ),
        ));

// this needs to be global because the audioplayerwidget is rebuilt on every click
Map<String, PlayerSoundRecorder> globalAudioPlayers = {};

class AudioPlayerWidget extends StatelessWidget {
  String filePath;

  AudioPlayerWidget({required this.filePath}) {
    if (!globalAudioPlayers.containsKey(filePath)) {
      globalAudioPlayers[filePath] = PlayerSoundRecorder();
    }
  }

  @override
  Widget build(BuildContext context) {
    PlayerSoundRecorder? playerSoundRecorder = globalAudioPlayers[filePath];
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) =>
            playerSoundRecorder!.getPlayerSection(filePath));
  }
}

class AudioPlayerEmbedBuilder implements EmbedBuilder {
  @override
  String get key => 'audioPlayer';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
  ) {
    return AudioPlayerWidget(filePath: node.value.data);
  }
}

class AudioPlayerBlockEmbed extends CustomBlockEmbed {
  const AudioPlayerBlockEmbed(String value) : super(noteType, value);

  static const String noteType = 'audioPlayer';
}
