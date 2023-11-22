/// FileName minx_music
///
/// @Author liujunjie
/// @Date 2023/11/21 16:40
///
/// @Description TODO

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'widgets/capacity_indicators.dart';
import 'widgets/popup.dart';
import 'dart:convert' show base64;
import 'audio_metadata.dart';
import 'widgets/control_buttons.dart';
import 'widgets/marquee.dart';
import 'package:id3/id3.dart';

mixin MusicMixin<T extends StatefulWidget> on State<T> {
  late AudioPlayer _player;
  final playList = ConcatenatingAudioSource(children: []);
  final _addGlobalKey = GlobalKey();

  setupInit({required AudioPlayer player}) {
    _player = player;
  }

  Widget bottomToolView({GestureTapCallback? onTap, bool down = false}) {
    return Container(
      color: const Color(0xFFF5F2F0),
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _musicInfoView(onTap: onTap, down: down),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _settingsBtnView(),
                ),
              ],
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(
            children: [
              ControlButtons(player: _player),
              SizedBox(width: 400, child: _progressBarView())
            ],
          )
        ])
      ]),
    );
  }

  bool _showplayBar = false;

  /// 播放当前音频的信息
  Widget _musicInfoView({GestureTapCallback? onTap, bool down = false}) {
    return StreamBuilder<SequenceState?>(
      stream: _player.sequenceStateStream,
      builder: (context, snapshot) {
        print("-----------");
        final state = snapshot.data;
        if (state?.sequence.isEmpty ?? true) {
          return const SizedBox();
        }
        final metadata = state!.currentSource!.tag as AudioMetadata;

        return Row(
          children: [
            MouseRegion(
              onEnter: (event) {
                setState(() {
                  _showplayBar = true;
                });
              },
              onExit: (event) {
                setState(() {
                  _showplayBar = false;
                });
              },
              child: Stack(
                children: [
                  SizedBox(
                      width: 60,
                      height: 60,
                      child: metadata.artwork.isNotEmpty
                          ? Image.memory(
                              base64.decode(metadata.artwork),
                            )
                          : Image.asset('images/music.png')),
                  if (_showplayBar)
                    InkWell(
                      child: Opacity(
                          opacity: 0.7,
                          child: Image.asset(
                              'images/playBar'+ (down?'Close':'Open')+'SingleSong.png',
                              width: 60,
                              height: 60)),
                      onTap: onTap,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShowNameText(metadata.title),
                Text(metadata.artist,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black87)),
                StreamBuilder<PositionData>(
                  stream: positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;

                    final textTime = handleTime(positionData?.position) +
                        " / " +
                        handleTime(positionData?.duration);

                    return Text(textTime,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black54));
                  },
                )
              ],
            )
          ],
        );
      },
    );
  }

  ///进度条
  Widget _progressBarView() {
    return StreamBuilder<PositionData>(
      stream: positionDataStream,
      builder: (context, snapshot) {
        final positionData = snapshot.data;
        final position = positionData?.position ?? Duration.zero;
        final duration = positionData?.duration ?? Duration.zero;
        final bufferedPosition =
            positionData?.bufferedPosition ?? Duration.zero;
        return CapacityIndicator(
          color: Colors.red,
          bufferedColor: Colors.red.shade100,
          initialValue: position.inMilliseconds.toDouble(),
          max: duration.inMilliseconds.toDouble(),
          bufferedValue: bufferedPosition.inMilliseconds.toDouble(),
          onChanged: (v) {
            _player.seek(Duration(milliseconds: v.round()));
          },
        );
      },
    );
  }

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  /// 获取本地音频
  Future<void> _openMusicFile() async {
    const XTypeGroup mp3TypeGroup = XTypeGroup(
      label: 'MP3',
      extensions: <String>['mp3', 'MP3'],
    );

    const XTypeGroup m4aTypeGroup = XTypeGroup(
      label: 'm4a',
      extensions: <String>['m4a', 'M4A'],
    );

    final List<XFile> files = await openFiles(
        acceptedTypeGroups: <XTypeGroup>[mp3TypeGroup, m4aTypeGroup]);
    if (files.isEmpty) return;

    // List<String> saveFlies = [];

    for (var f in files) {
      List<int> mp3Bytes = await f.readAsBytes();
      MP3Instance mp3instance = MP3Instance(mp3Bytes);
      if (mp3instance.parseTagsSync()) {
        final tag = mp3instance.getMetaTags()!;
        var name = tag["Title"];
        if (name == null || name == "") {
          name = f.name.replaceAll(RegExp(r'.mp3|.MP3|m4a|M4A'), '');
        }
        final artist = tag["Artist"];
        final lyrics = tag["USLT"]?["lyrics"];
        final artwork = tag["APIC"]?["base64"];
        final m = AudioMetadata(
            title: name,
            artwork: artwork ?? "",
            artist: artist ?? "未知",
            lyrics: lyrics ?? '',
            path: f.path);
        await playList.add(AudioSource.uri(Uri.file(f.path), tag: m));
        // saveFlies.add(m.toJsonString());
      }
    }
    await _player.load();
  }

  Widget _settingsBtnView() {
    return IconButton(
        key: _addGlobalKey,
        onPressed: () {
          RenderBox renderBox =
              _addGlobalKey.currentContext?.findRenderObject() as RenderBox;
          Rect box = renderBox.localToGlobal(Offset.zero) & renderBox.size;
          box = box.translate(-60, -60);
          Popup.showPopupWindow(
              context: context,
              offset: box.topLeft,
              child: (closeFunc) => Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        TextButton(
                            onPressed: () async {
                              await _openMusicFile();
                            },
                            child: const Text("添加音频")),
                        TextButton(
                            onPressed: () async {
                              await playList.clear();
                            },
                            child: const Text("清除音频")),
                      ],
                    ),
                  ));
        },
        icon: const Icon(Icons.settings_rounded));
  }

  Widget _buildShowNameText(String txt) {
    return SizedBox(
        width: 150,
        height: 30,
        child: Marquee(
          text: txt,
          style: const TextStyle(
            fontSize: 14,
          ),
          blankSpace: 20.0,
          startPadding: 10.0,
          velocity: 40,
        ));
  }

  String handleTime(Duration? duration) {
    if (duration == null) return '';

    return RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
            .firstMatch("$duration")
            ?.group(1) ??
        '$duration';
  }
}
