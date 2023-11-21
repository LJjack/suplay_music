/// FileName detail
///
/// @Author liujunjie
/// @Date 2023/11/21 11:30
///
/// @Description 音乐详情界面

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:suplay_music/mixin_music.dart';

class Detail extends StatefulWidget {
  const Detail({super.key, required this.player});

  final AudioPlayer player;

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> with MusicMixin {
  AudioPlayer get _player => widget.player;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setupInit(player: _player);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Container(color: Colors.white)),
            const Divider(),
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
