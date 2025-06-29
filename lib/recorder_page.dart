import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recordings_page.dart';

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> with WidgetsBindingObserver {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _recordedFilePath;
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndRequestMicPermission();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<bool> _checkAndRequestMicPermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Mikrofon izni kalıcı olarak reddedildi. Ayarlardan izin verin."),
          action: SnackBarAction(
            label: 'Aç',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
      return false;
    }

    final result = await Permission.microphone.request();

    if (!result.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mikrofon izni gerekli!")),
      );
      return false;
    }

    return true;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _startRecording() async {
    final hasPermission = await _checkAndRequestMicPermission();
    if (!hasPermission) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giriş yapılmadan kayıt yapılamaz.")),
      );
      return;
    }

    Directory baseDir = await getApplicationDocumentsDirectory();
    String userDirPath = '${baseDir.path}/${user.uid}';
    Directory userDir = Directory(userDirPath);
    if (!await userDir.exists()) {
      await userDir.create(recursive: true);
    }

    String filePath = '$userDirPath/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

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
    await _recorder.stopRecorder();
    _timer?.cancel();

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
                'Kayıt başarıyla kaydedildi',
                style: GoogleFonts.poppins(color: Colors.white),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Ses Kaydedici',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.redAccent : Colors.deepPurple.shade100,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isRecording ? Colors.red.withOpacity(0.4) : Colors.deepPurple.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  size: 60,
                  color: _isRecording ? Colors.white : Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isRecording ? _formatDuration(_recordDuration) : "Hazır",
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: _isRecording ? Colors.redAccent : Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                label: Text(_isRecording ? 'Kaydı Durdur' : 'Kayda Başla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.redAccent : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                onPressed: _isRecording ? _stopRecording : _startRecording,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecordingsPage()),
                  );
                },
                icon: const Icon(Icons.library_music),
                label: const Text("Kayıtlarım"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
