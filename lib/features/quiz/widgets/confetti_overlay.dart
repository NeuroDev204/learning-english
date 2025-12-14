// confetti_overlay.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatelessWidget {
  final ConfettiController controller;
  const ConfettiOverlay({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirection: -3.14 / 2,
        emissionFrequency: 0.05,
        numberOfParticles: 30,
        gravity: 0.2,
      ),
    );
  }
}
