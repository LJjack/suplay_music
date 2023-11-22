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
  ScrollController? controller;
  List<Duration> timeList = [];
  List<String> lyricsList = [];
  StreamSubscription? lyricsStream;

  int currentIndex = -1;

  @override
  void initState() {
    super.initState();
    setupInit(player: _player);


    controller = ScrollController();
    lyricsStream = positionDataStream.listen((event) {
      if (lyricsList.isEmpty)  return;
      int index =  timeList.indexWhere((element) => event.position<element) - 1;
      if (index <= 0) index = 0;
      if (currentIndex == index) return;

      if (index < lyricsList.length) {
        controller?.animateTo(
          index * 40.0 ,  // 滚动位置
          duration: const Duration(milliseconds: 200),  // 滚动动画的持续时间
          curve: Curves.ease,  // 滚动动画的曲线
        );

      }

    });
  }

  Duration parseDuration(String s) {
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
                    final metadata = state!.currentSource!.tag as AudioMetadata;
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

                      timeList.add(parseDuration(time));

                      lyricsList.add(lyrics);
                    }
                    if(lyricsList.isEmpty) {
                      return const Center(child: Text("无歌词显示"));
                    }


                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ListWheelScrollView.useDelegate(
                              controller: controller,
                              itemExtent: 40,
                              childDelegate: ListWheelChildBuilderDelegate(
                                  builder: (cxt, index) {
                                    return Text(
                                      lyricsList[index],
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 18),
                                    );
                                  },
                                  childCount: lyricsList.length)),
                        ),
                        const Center(child: Divider(color: Colors.red,thickness: 2.0,indent: 260,endIndent: 260,))
                      ],
                    );
                  }
                )),
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
}
