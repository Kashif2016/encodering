import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:logging/logging.dart';
import 'package:audio_player_app/translations.dart';
import 'package:flutter/services.dart'; // Import the services package
import 'dart:ui';
import 'package:audio_player_app/utils/audio_functions.dart';
import 'package:audio_player_app/screens/play_audio_screen.dart';
import 'package:audio_player_app/providers/audio_provider.dart';
import 'package:provider/provider.dart';

class QRScanScreen extends StatefulWidget {
  final Function(String) onScanned;

  const QRScanScreen({super.key, required this.onScanned});

  @override
  QRScanScreenState createState() => QRScanScreenState();
}

class QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController controller = MobileScannerController(
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.aztec,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.itf,
      BarcodeFormat.pdf417,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  final Logger _logger = Logger('QRScanScreen');
  late String _languageCode;
  late AudioFunctions _audioFunctions;

  @override
  void initState() {
    super.initState();
    _setLanguageCode();
    _setFullScreenMode();
    _audioFunctions = AudioFunctions(context);
  }

  void _setLanguageCode() {
    final locale = PlatformDispatcher.instance.locale;
    switch (locale.languageCode) {
      case 'de':
        _languageCode = 'de';
        break;
      case 'ja':
        _languageCode = 'ja';
        break;
      default:
        _languageCode = 'en';
    }
  }

  void _setFullScreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture barcodeCapture) async {
              final String? code = barcodeCapture.barcodes.first.rawValue;
              if (code != null && mounted) {
                final audioId = _extractAudioId(code);
                if (audioId != null) {
                  _logger.info('audioId: $audioId');
                  widget.onScanned(audioId);
                  controller.stop(); // Stop the scanner
                  await _handleScannedCode(audioId);
                } else {
                  _logger.warning('No audio ID found in the scanned text');
                }
              }
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 150.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.width * 0.6,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white, width: 4),
                            left: BorderSide(color: Colors.white, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white, width: 4),
                            right: BorderSide(color: Colors.white, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 4),
                            left: BorderSide(color: Colors.white, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 4),
                            right: BorderSide(color: Colors.white, width: 4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                Translations.getTranslation(_languageCode, 'scan'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _extractAudioId(String url) {
    String audioId = url.split('/').last;
    if (audioId.endsWith('.wav')) {
      audioId = audioId.replaceAll('.wav', '');
    }
    return audioId;
  }

  Future<void> _handleScannedCode(String code) async {
    try {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      await _audioFunctions.fetchAudio(context, code);
      final currentAudio =
          audioProvider.audios.isNotEmpty ? audioProvider.audios.last : null;

      if (currentAudio != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayAudioScreen(
              audioId: currentAudio.id,
              imageUrl: currentAudio.imageUrl,
              audioUrl: currentAudio.url,
            ),
          ),
        );
      } else {
        // Handle error if audio is not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio not found')),
        );
      }
    } catch (e) {
      _logger.severe('Error fetching audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching audio')),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
