// widgets/countdown_timer.dart
import 'dart:async';

import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback onComplete;
  final TextStyle? textStyle;
  final int tunueCoins;

  const CountdownTimer({
    Key? key,
    required this.duration,
    required this.onComplete,
    required this.tunueCoins,
    this.textStyle,
  }) : super(key: key);

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration _remainingTime;
  static const Duration maxDuration = Duration(hours: 12);

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.duration;

    // Aggiorna il timer ogni secondo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else {
          _timer.cancel();
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se il timer è a zero, mostra la barra completamente verde
    if (_remainingTime.inSeconds <= 0) {
      return _buildProgressBar(1.0);
    }

    // Calcola il progresso (0.0 = 12 ore rimaste, 1.0 = 0 ore rimaste)
    final progress = 1.0 - (_remainingTime.inSeconds / maxDuration.inSeconds);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return _buildProgressBar(clampedProgress);
  }

  Widget _buildProgressBar(double progress) {
    const double barWidth = 216.0;
    const double barHeight = 16.0;
    const double iconSize = 56.0;

    // Calcola la posizione dell'icona
    final iconPosition = (barWidth - iconSize + 40) * progress;

    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes.remainder(60);
    final seconds = _remainingTime.inSeconds.remainder(60);

    return Column(
      children: [
        // Barra di progresso con logo sopra
        SizedBox(
          width: barWidth +
              56, // Aumento lo spazio per il logo che si sposta a destra
          height:
              iconSize + 20, // Riduco l'altezza per aderire meglio al contenuto
          child: Stack(
            children: [
              // Barra di progresso centrata verticalmente
              Positioned(
                left: 28, // Centro la barra nel container più largo (56/2 = 28)
                top: (iconSize - barHeight) / 2, // Centra la barra nello stack
                child: Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFDBDDE7), width: 2.4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3D3D3D).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // Sfondo bianco
                        Container(
                          width: barWidth,
                          height: barHeight,
                          color: Colors.white,
                        ),
                        // Parte verde (progresso)
                        Container(
                          width: barWidth * progress,
                          height: barHeight,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF18FB3D),
                                Color(0xFF4BFF9E),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Badge Tunuè Coins posizionato esattamente sotto il logo
              Positioned(
                left: iconPosition +
                    8 +
                    (iconSize / 2) -
                    21, // Aggiusto per seguire il logo
                top: (iconSize) / 2 + 10.5, // Più in basso
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF18FB3D),
                          Color(0xFF4BFF9E),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Text(
                        '${widget.tunueCoins}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Logo che si muove davanti alla barra (ora sopra il badge)
              Positioned(
                left: iconPosition +
                    8, // Riduco l'offset per spostarlo più a sinistra
                top: -2, // Alzato di soli 2 pixel
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Image.asset(
                      'assets/images/icons/tunue_logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.access_time,
                          color: Color(0xFF4CAF50),
                          size: 40,
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Timer numerico posizionato alla stessa altezza del badge
              Positioned(
                left: 28, // Aggiusto per la barra centrata
                right: 28, // Aggiusto per la barra centrata
                top: (iconSize) / 2 +
                    16, // Sposto più in basso (era +12, ora +16)
                child: _remainingTime.inSeconds > 0
                    ? Container(
                        alignment: _remainingTime.inHours >= 6
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        padding: _remainingTime.inHours >= 6
                            ? const EdgeInsets.only(right: 4)
                            : const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Color(0xFFACB0B3),
                            ),
                            const SizedBox(width: 2),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFACB0B3),
                                  fontFamily: 'NeueHaasDisplay',
                                ),
                                children: [
                                  TextSpan(
                                    text: hours.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'NeueHaasDisplay',
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'h ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      fontFamily: 'NeueHaasDisplay',
                                    ),
                                  ),
                                  TextSpan(
                                    text: minutes.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'NeueHaasDisplay',
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'm',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      fontFamily: 'NeueHaasDisplay',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
