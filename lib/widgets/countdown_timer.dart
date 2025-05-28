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
    const double barWidth = 280.0;
    const double barHeight = 24.0;
    const double iconSize = 32.0;

    // Calcola la posizione dell'icona
    final iconPosition = (barWidth - iconSize) * progress;

    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes.remainder(60);
    final seconds = _remainingTime.inSeconds.remainder(60);

    return Column(
      children: [
        // Barra di progresso
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!, width: 2),
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
                        Color(0xFF4CAF50),
                        Color(0xFF8BC34A),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                // Icona che si muove
                Positioned(
                  left: iconPosition,
                  top: (barHeight - iconSize) / 2,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Tunuè Coins sotto l'icona
        Container(
          margin: EdgeInsets.only(left: iconPosition),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.tunueCoins}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Timer testuale (opzionale, per debug o informazione aggiuntiva)
        if (_remainingTime.inSeconds > 0)
          Text(
            'Prossimo pacchetto gratuito tra: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: widget.textStyle ??
                const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
          )
        else
          Text(
            'Pacchetto gratuito disponibile!',
            style: widget.textStyle ??
                const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
          ),
      ],
    );
  }
}
