import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recordings_page.dart';
import 'localization_manager.dart';

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _recordedFilePath;
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  @override
  void dispose() {
    if (_recorder.isRecording) {
      _recorder.stopRecorder();
    }
    _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    // Permission request moved to start recording or initial check
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
    await _recorder.openRecorder();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _startRecording() async {
    final localization = LocalizationManager();
    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (!status.isGranted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission required")),
      );
      return;
    }

    Directory baseDir = await getApplicationDocumentsDirectory();
    // Using a common folder instead of user-specific
    String recordingsPath = '${baseDir.path}/recordings';
    Directory recordingsDir = Directory(recordingsPath);
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    // Name: YYYY-MM-DD HH-mm-ss.aac
    String timestamp = DateTime.now().toString().split('.')[0].replaceAll(':', '-');
    String filePath = '$recordingsPath/$timestamp.aac';

    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });

    setState(() {
      _isRecording = true;
      _recordedFilePath = filePath;
    });
  }

  Future<void> _stopRecording() async {
    final localization = LocalizationManager();
    await _recorder.stopRecorder();
    _timer?.cancel();

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localization.translate('recording_stopped'),
                style: GoogleFonts.robotoMono(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localization = LocalizationManager();

    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'STUDIO REC',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
         decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                const Color(0xFF1E2336), 
                colorScheme.background,
              ],
            ),
          ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Timer Display with Neon Glow
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _isRecording ? colorScheme.error : colorScheme.primary.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? colorScheme.error : colorScheme.primary).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Text(
                    _isRecording ? _formatDuration(_recordDuration) : "00:00",
                    style: GoogleFonts.robotoMono( 
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isRecording ? localization.translate('recording_started') : localization.translate('tap_to_record'),
                  style: GoogleFonts.orbitron(
                    color: _isRecording ? colorScheme.error : Colors.white54,
                    fontSize: 14,
                    letterSpacing: 2.0,
                  ),
                ),

                const SizedBox(height: 80),

                // Studio Mic Button (Glowing Orb)
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isRecording ? 180 : 160,
                    width: _isRecording ? 180 : 160,
                    decoration: BoxDecoration(
                      color: _isRecording ? colorScheme.error.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isRecording ? colorScheme.error : colorScheme.primary,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? colorScheme.error : colorScheme.primary)
                              .withOpacity(_isRecording ? 0.6 : 0.4),
                          blurRadius: _isRecording ? 50 : 30,
                          spreadRadius: _isRecording ? 10 : 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        height: 80,
                        width: 80,
                         decoration: BoxDecoration(
                          color: _isRecording ? colorScheme.error : colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),

                // Bottom Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildOptionButton(
                      context,
                      icon: Icons.list_rounded,
                      label: localization.translate('record_book'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RecordingsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
