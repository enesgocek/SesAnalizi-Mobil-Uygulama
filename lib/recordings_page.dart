import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pitch_graph_page.dart';

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  List<FileSystemEntity> _recordings = [];
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  String? _currentPlayingPath;
  String? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
    _loadRecordings();
  }

  void _showCustomSnackBar(String message, {Color color = Colors.deepPurple, IconData icon = Icons.info}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadRecordings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showCustomSnackBar("Giriş yapılmadan kayıtlar görüntülenemez.", color: Colors.redAccent, icon: Icons.error);
      return;
    }

    Directory baseDir = await getApplicationDocumentsDirectory();
    Directory userDir = Directory('${baseDir.path}/${user.uid}');
    if (!await userDir.exists()) {
      setState(() {
        _recordings = [];
      });
      return;
    }

    List<FileSystemEntity> files = userDir.listSync();
    List<FileSystemEntity> aacFiles = files.where((f) => f.path.endsWith('.aac')).toList();

    setState(() {
      _recordings = aacFiles.reversed.toList();
    });
  }

  Future<String?> _getUserGender() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['gender'];
  }

  Future<void> _analyzeRecording(String filePath) async {
    final userGender = await _getUserGender();
    if (userGender == null) {
      _showCustomSnackBar("Cinsiyet bilgisi alınamadı.", color: Colors.orange, icon: Icons.warning);
      return;
    }

    final uri = Uri.parse("http://10.0.2.2:5000/analyze");
    final file = File(filePath);
    final mimeType = lookupMimeType(filePath) ?? 'audio/aac';

    _showCustomSnackBar("Analiz ediliyor...", color: Colors.deepPurple, icon: Icons.analytics);

    try {
      final request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType.parse(mimeType),
        ))
        ..fields['gender'] = userGender;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final voiceType = data['voice_type'];
        final pitch = data['average_pitch'];
        final time = data['processing_time'];
        final List<double> pitchSeries = List<double>.from(data['pitch_series']);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PitchGraphPage(
              pitchSeries: pitchSeries,
              voiceType: voiceType,
              averagePitch: pitch,
              processingTime: time.toString(),
            ),
          ),
        );
      } else {
        final error = jsonDecode(responseBody)['message'] ?? "Hata oluştu.";
        _showCustomSnackBar("Hata: $error", color: Colors.redAccent, icon: Icons.error);
      }
    } catch (e) {
      _showCustomSnackBar("Bağlantı hatası: $e", color: Colors.redAccent, icon: Icons.error);
    }
  }

  Future<void> _renameRecording(String oldPath) async {
    final oldFile = File(oldPath);
    final directory = oldFile.parent;

    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yeniden Adlandır"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Yeni dosya adı"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          TextButton(
            onPressed: () async {
              String newName = controller.text.trim();
              if (newName.isNotEmpty) {
                String newPath = '${directory.path}/$newName.aac';
                await oldFile.rename(newPath);
                _loadRecordings();
                Navigator.pop(ctx);
                _showCustomSnackBar("Kayıt adı güncellendi", color: Colors.green.shade600, icon: Icons.check_circle);
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecording(String path) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kayıt Sil"),
        content: Text("${path.split('/').last} adlı kaydı silmek istiyor musunuz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sil")),
        ],
      ),
    );

    if (shouldDelete == true) {
      File(path).deleteSync();
      _loadRecordings();
      if (_selectedFilePath == path) {
        setState(() {
          _selectedFilePath = null;
        });
      }
      _showCustomSnackBar("Kayıt silindi", color: Colors.red.shade400, icon: Icons.delete);
    }
  }

  Future<void> _togglePlayback(String filePath) async {
    if (_isPlaying && _currentPlayingPath == filePath) {
      await _player.stopPlayer();
      setState(() {
        _isPlaying = false;
        _currentPlayingPath = null;
      });
    } else {
      if (_isPlaying) {
        await _player.stopPlayer();
      }
      await _player.startPlayer(
        fromURI: filePath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _currentPlayingPath = null;
          });
        },
      );
      setState(() {
        _isPlaying = true;
        _currentPlayingPath = filePath;
      });
    }
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Kayıtlarım',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: ElevatedButton.icon(
              onPressed: _selectedFilePath == null
                  ? null
                  : () => _analyzeRecording(_selectedFilePath!),
              icon: const Icon(Icons.analytics),
              label: const Text("Seçili Kaydı Analiz Et"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedFilePath == null
                    ? Colors.grey
                    : Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _recordings.isEmpty
                ? const Center(child: Text("Henüz kayıt yok."))
                : ListView.builder(
              itemCount: _recordings.length,
              itemBuilder: (context, index) {
                String path = _recordings[index].path;
                String name = path.split('/').last;

                return Card(
                  color: _selectedFilePath == path
                      ? Colors.deepPurple.shade50
                      : Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: IconButton(
                      icon: Icon(
                        (_isPlaying && _currentPlayingPath == path)
                            ? Icons.stop
                            : Icons.play_arrow,
                        color: Colors.deepPurple,
                        size: 30,
                      ),
                      onPressed: () => _togglePlayback(path),
                    ),
                    title: Text(
                      name,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'rename') {
                          _renameRecording(path);
                        } else if (value == 'delete') {
                          _deleteRecording(path);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text("Yeniden Adlandır"),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text("Sil"),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedFilePath = path;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}