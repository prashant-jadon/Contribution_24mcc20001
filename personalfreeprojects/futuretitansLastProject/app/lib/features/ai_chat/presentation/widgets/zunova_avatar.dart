import 'package:flutter/material.dart';

class ZunovaAvatar extends StatelessWidget {
  final bool isTalking;
  final double size;

  const ZunovaAvatar({
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
            ? 'assets/animations/zunova_talk.webp'
            : 'assets/animations/zunova_idle.webp',
        fit: BoxFit.contain,
        gaplessPlayback: true, // Smooth transition between idle and talk
      ),
    );
  }
}
