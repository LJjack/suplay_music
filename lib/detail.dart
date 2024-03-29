/// FileName detail
///
/// @Author liujunjie
/// @Date 2023/11/21 11:30
///
/// @Description 音乐详情界面

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'mixin_music.dart';

import 'audio_metadata.dart';

class Detail extends StatefulWidget {
  const Detail({super.key, required this.player});

  final AudioPlayer player;

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> with MusicMixin {
  AudioPlayer get _player => widget.player;
  FixedExtentScrollController? controller;
  List<Duration> timeList = [];
  List<String> lyricsList = [];
  StreamSubscription? lyricsStream;

  int currentIndex = -1;
  late StreamController<int> lyricsController;

  @override
  void initState() {
    super.initState();
    lyricsController = StreamController<int>();
    controller = FixedExtentScrollController();

    lyricsStream = positionDataStream.listen((event) {
      if (lyricsList.isEmpty) return;
      int index =
          timeList.indexWhere((element) => event.position < element) - 1;
      if (index <= 0) index = 0;
      if (currentIndex == index) return;
      if (index < lyricsList.length) {
        currentIndex = index;
        lyricsController.add(index);
        controller?.animateToItem(
          index, // 滚动位置
          duration: const Duration(milliseconds: 200), // 滚动动画的持续时间
          curve: Curves.ease, // 滚动动画的曲线
        );
      }
    });
  }

  Duration? parseDuration(String s) {
    if (!s.contains('.') || !s.contains(":")) {
      return null;
    }
    int hours = 0;
    int minutes = 0;
    int micros;
    List<String> parts = s.split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
    return Duration(hours: hours, minutes: minutes, microseconds: micros);
  }

  @override
  void dispose() {
    controller?.dispose();
    lyricsStream?.cancel();
    lyricsController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
                child: StreamBuilder<SequenceState?>(
                    stream: _player.sequenceStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      if (state?.sequence.isEmpty ?? true) {
                        return const SizedBox();
                      }
                      final metadata =
                          state!.currentSource!.tag as AudioMetadata;
                      timeList.clear();
                      lyricsList.clear();
                      for (final text in metadata.lyrics.split('\n')) {
                        RegExp regex = RegExp(r'\[\s*(.*)\]\s*(.*)');
                        var match = regex.firstMatch(text);
                        if (match == null) {
                          continue;
                        }
                        String time = match.group(1) ?? "";
                        String lyrics = match.group(2) ?? "";
                        final timeD = parseDuration(time);
                        if (timeD != null) {
                          timeList.add(timeD);
                          lyricsList.add(lyrics);
                        }
                      }
                      if (lyricsList.isEmpty) {
                        return const Center(child: Text("无歌词显示"));
                      }

                      return StreamBuilder<int>(
                          stream: lyricsController.stream,
                          builder: (context, snapshot) {

                            return ListWheelScrollView.useDelegate(
                                controller: controller,
                                itemExtent: 40,
                                childDelegate: ListWheelChildBuilderDelegate(
                                    builder: (cxt, index) {
                                      return Text(
                                        lyricsList[index],
                                        style: index == snapshot.data
                                            ? const TextStyle(
                                                color: Colors.red, fontSize: 20)
                                            : const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16),
                                      );
                                    },
                                    childCount: lyricsList.length));
                          });
                    })),
            bottomToolView(
                onTap: () {
                  Navigator.of(context).pop();
                },
                down: true)
          ],
        ),
      ),
    );
  }

  @override
  AudioPlayer get player => _player;
}
