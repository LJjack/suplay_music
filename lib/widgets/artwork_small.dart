/// FileName artwork_small
///
/// @Author liujunjie
/// @Date 2023/11/23 15:28
///
/// @Description 显示音乐封面

import 'package:flutter/material.dart';
import 'dart:convert' show base64;

class ArtworkSmall extends StatefulWidget {
  const ArtworkSmall(
      {super.key, required this.artwork, this.down = false, this.onTap});

  final String artwork;
  final bool down;
  final GestureTapCallback? onTap;

  @override
  State<ArtworkSmall> createState() => _ArtworkSmallState();
}

class _ArtworkSmallState extends State<ArtworkSmall> {
  bool _showPlayBar = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _showPlayBar = true;
        });
      },
      onExit: (event) {
        setState(() {
          _showPlayBar = false;
        });
      },
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          children: [
            widget.artwork.isNotEmpty
                ? Image.memory(base64.decode(widget.artwork))
                : Image.asset('images/music.png'),
            if (_showPlayBar)
              GestureDetector(
                child: Opacity(
                    opacity: 0.7,
                    child: Image.asset('images/playBar' +
                        (widget.down ? 'Close' : 'Open') +
                        'SingleSong.png')),
                onTap: widget.onTap,
              ),
          ],
        ),
      ),
    );
  }
}
