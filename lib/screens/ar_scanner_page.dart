import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

class ARScannerPage extends StatefulWidget {
  const ARScannerPage({super.key});

  @override
  _ARScannerPageState createState() => _ARScannerPageState();
}

class _ARScannerPageState extends State<ARScannerPage> {
  VideoPlayerController? _videoController;

  bool _isMarkerDetected = false;
  bool _isVideoPlaying = false;
  bool _isScanning = true;
  String _statusMessage = 'Punta la camera verso il marker';
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scansione in corso...';
    });

    // Simula il riconoscimento del marker dopo 3 secondi
    _scanTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _onMarkerDetected();
      }
    });
  }

  void _onMarkerDetected() {
    setState(() {
      _isMarkerDetected = true;
      _isScanning = false;
      _statusMessage = 'Marker rilevato! Caricamento video...';
    });

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Inizializza il video player con un video di esempio
      _videoController = VideoPlayerController.asset(
        'assets/videos/immersive_card.mp4',
      );

      await _videoController!.initialize();

      setState(() {
        _isVideoPlaying = true;
        _statusMessage = 'Video AR attivo';
      });

      // Avvia il video in loop
      _videoController!.setLooping(true);
      _videoController!.play();
    } catch (e) {
      setState(() {
        _statusMessage = 'Errore caricamento video: $e';
      });
    }
  }

  void _resetAR() {
    setState(() {
      _isMarkerDetected = false;
      _isVideoPlaying = false;
      _isScanning = false;
      _statusMessage = 'Punta la camera verso il marker';
    });

    _videoController?.pause();
    _videoController?.seekTo(Duration.zero);

    // Riavvia la scansione
    _startScanning();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Simulazione vista camera
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a1a),
                  Color(0xFF2d2d2d),
                  Color(0xFF1a1a1a),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                'Vista Camera\n(Simulata)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'NeueHaasDisplay',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),

          // Overlay video AR
          if (_isMarkerDetected && _isVideoPlaying && _videoController != null)
            Positioned(
              left: MediaQuery.of(context).size.width * 0.2,
              top: MediaQuery.of(context).size.height * 0.3,
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/icons/svg/arrow_icon.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Scanner AR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'NeueHaasDisplay',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(
                          width: 36), // Per bilanciare il back button
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Status bar in basso
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicatore di stato
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _isMarkerDetected
                            ? Colors.green.withOpacity(0.8)
                            : _isScanning
                                ? Colors.blue.withOpacity(0.8)
                                : Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isScanning)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else
                            Icon(
                              _isMarkerDetected
                                  ? Icons.check_circle
                                  : Icons.search,
                              color: Colors.white,
                              size: 20,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'NeueHaasDisplay',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isMarkerDetected) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Bottone reset
                          GestureDetector(
                            onTap: _resetAR,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Reset',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontFamily: 'NeueHaasDisplay',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottone pausa/play video
                          if (_videoController != null)
                            GestureDetector(
                              onTap: () {
                                if (_videoController!.value.isPlaying) {
                                  _videoController!.pause();
                                } else {
                                  _videoController!.play();
                                }
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _videoController!.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _videoController!.value.isPlaying
                                          ? 'Pausa'
                                          : 'Play',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'NeueHaasDisplay',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    // Istruzioni
                    if (!_isMarkerDetected) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              '📱 Come usare lo Scanner AR:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'NeueHaasDisplay',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '1. Punta la camera verso un marker\n'
                              '2. Mantieni il dispositivo stabile\n'
                              '3. Attendi il riconoscimento automatico\n'
                              '4. Goditi il video in realtà aumentata!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'NeueHaasDisplay',
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Overlay per il targeting del marker
          if (!_isMarkerDetected)
            Positioned.fill(
              child: CustomPaint(
                painter: MarkerOverlayPainter(),
              ),
            ),

          // Effetto di scansione
          if (_isScanning)
            Positioned.fill(
              child: CustomPaint(
                painter: ScanningEffectPainter(),
              ),
            ),
        ],
      ),
    );
  }
}

class MarkerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final squareSize = size.width * 0.6;
    final rect = Rect.fromCenter(
      center: center,
      width: squareSize,
      height: squareSize,
    );

    // Disegna gli angoli del targeting
    const cornerLength = 30.0;

    // Angolo in alto a sinistra
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(0, cornerLength),
      paint,
    );

    // Angolo in alto a destra
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(-cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, cornerLength),
      paint,
    );

    // Angolo in basso a sinistra
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(0, -cornerLength),
      paint,
    );

    // Angolo in basso a destra
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(-cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(0, -cornerLength),
      paint,
    );

    // Testo di istruzione
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Posiziona il marker qui',
        style: TextStyle(
          color: Colors.cyan,
          fontSize: 16,
          fontFamily: 'NeueHaasDisplay',
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        rect.bottom + 20,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanningEffectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Disegna cerchi concentrici animati
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        (size.width * 0.1) * i,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
