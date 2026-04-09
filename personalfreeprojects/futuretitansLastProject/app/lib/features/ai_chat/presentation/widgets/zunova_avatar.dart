import 'package:flutter/material.dart';

class zunnovaAvatar extends StatelessWidget {
  final bool isTalking;
  final double size;

  const zunnovaAvatar({
    super.key,
    this.isTalking = false,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        isTalking
            ? 'assets/animations/zunnova_talk.webp'
            : 'assets/animations/zunnova_idle.webp',
        fit: BoxFit.contain,
        gaplessPlayback: true, // Smooth transition between idle and talk
      ),
    );
  }
}
