import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pitch_graph_page.dart';
import 'localization_manager.dart';

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  List<FileSystemEntity> _recordings = [];
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isLoading = false; // Added loading state
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
    Directory baseDir = await getApplicationDocumentsDirectory();
    String recordingsPath = '${baseDir.path}/recordings';
    Directory recordingsDir = Directory(recordingsPath);

    if (await recordingsDir.exists()) {
      List<FileSystemEntity> files = recordingsDir
          .listSync()
          .where((item) => item.path.endsWith('.aac'))
          .toList();

      // Legacy patterns to migrate
      final RegExp legacyPattern1 = RegExp(r'^recording_\d+\.aac$');
      final RegExp legacyPattern2 = RegExp(r'^Kayıt \d+\.aac$');

      for (var entity in files) {
        if (entity is File) {
          String filename = entity.path.split(Platform.pathSeparator).last;
          
          // Only auto-rename if it matches a legacy/auto-generated pattern
          // This allows users to keep their custom names
          if (legacyPattern1.hasMatch(filename) || legacyPattern2.hasMatch(filename)) {
             try {
              // Get modification time
              DateTime modified = entity.statSync().modified;
              
              // Format: YYYY-MM-DD HH-mm-ss
              String formattedDate = modified.toString().split('.')[0].replaceAll(':', '-');
              
              String newName = '$formattedDate.aac';
              String newPath = '${recordingsDir.path}/$newName';
              
              if (entity.path != newPath) {
                 await entity.rename(newPath);
              }
            } catch (e) {
              print("Renaming error for ${entity.path}: $e");
            }
          }
        }
      }

      // Refresh list
      files = recordingsDir.listSync().where((item) => item.path.endsWith('.aac')).toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      setState(() {
        _recordings = files;
      });
    } else {
       setState(() {
        _recordings = [];
      });
    }
  }


  Future<String?> _showGenderSelectionDialog() async {
    final localization = LocalizationManager();
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localization.translate('voice_type_selection'),
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localization.translate('gender_prompt'),
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderButton(
                      ctx, localization.translate('female'), "Female", Icons.female, const Color(0xFFD500F9)
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGenderButton(
                      ctx, localization.translate('male'), "Male", Icons.male, const Color(0xFF00E5FF) // Cyan
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton(BuildContext ctx, String label, String value, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(ctx, value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(0.1),
             boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeRecording(String filePath) async {
    final localization = LocalizationManager();
    // 1. Ask for Gender
    final selectedGender = await _showGenderSelectionDialog();
    if (selectedGender == null) return; // User cancelled

    // 2. Proceed with Analysis
    final uri = Uri.parse("http://10.0.2.2:5000/analyze");
    final file = File(filePath);
    final mimeType = lookupMimeType(filePath) ?? 'audio/aac';

    setState(() => _isLoading = true); // Start Loading

    try {
      if (mounted) {
        _showCustomSnackBar(localization.translate('analyzing'), color: Colors.blueAccent, icon: Icons.troubleshoot);
      }
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType.parse(mimeType),
        ))
        ..fields['gender'] = selectedGender;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (!mounted) return;

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
        final error = jsonDecode(responseBody)['message'] ?? "Error occurred.";
        _showCustomSnackBar("${localization.translate('error')}: $error", color: Colors.redAccent, icon: Icons.error);
      }
    } catch (e) {
      _showCustomSnackBar("${localization.translate('connection_error')}: $e", color: Colors.redAccent, icon: Icons.error);
    } finally {
      if (mounted) setState(() => _isLoading = false); // Stop Loading
    }
  }

  Future<void> _renameRecording(String oldPath) async {
    final localization = LocalizationManager();
    final oldFile = File(oldPath);
    final directory = oldFile.parent;

    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localization.translate('rename_recording_title')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: localization.translate('new_file_name_hint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(localization.translate('cancel'))),
          TextButton(
            onPressed: () async {
              String newName = controller.text.trim();
              if (newName.isNotEmpty) {
                String newPath = '${directory.path}/$newName.aac';
                await oldFile.rename(newPath);
                
                if (!ctx.mounted) return;
                
                // We reload recordings in the parent widget scope
                // But _loadRecordings calls setState, so we need to be careful if we were outside.
                // Here we are inside the dialog's onPressed. 
                // Actually _loadRecordings is on the parent state.
                // We should pop first or ensure parent is mounted.
                // Since this is a closure, 'mounted' refers to State<RecordingsPage>.
                if (mounted) {
                   _loadRecordings();
                   Navigator.pop(ctx);
                   _showCustomSnackBar(localization.translate('recording_name_updated'), color: Colors.green.shade600, icon: Icons.check_circle);
                }
              }
            },
            child: Text(localization.translate('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecording(String path) async {
    final localization = LocalizationManager();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localization.translate('delete_recording_title')),
        content: Text(localization.translate('delete_recording_confirmation', {'filename': path.split('/').last})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(localization.translate('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(localization.translate('delete'))),
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
      _showCustomSnackBar(localization.translate('recording_deleted'), color: Colors.red.shade400, icon: Icons.delete);
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
    final colorScheme = Theme.of(context).colorScheme;
    final localization = LocalizationManager();

    return Scaffold(
      // Background handled by main theme or we can add gradient here for consistency
      body: Container(
        decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: [
                const Color(0xFF1E2336), 
                colorScheme.background,
              ],
            ),
          ),
        child: SafeArea(
          child: Column(
            children: [
               AppBar(
                title: Text(
                  localization.translate('record_book'),
                  style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_selectedFilePath == null || _isLoading)
                        ? null
                        : () => _analyzeRecording(_selectedFilePath!),
                    icon: _isLoading 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.graphic_eq),
                    label: Text(_isLoading ? localization.translate('processing') : localization.translate('start_analysis')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white10,
                      disabledForegroundColor: Colors.white30,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _recordings.isEmpty
                    ? Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.music_off_rounded, size: 64, color: Colors.white24),
                           const SizedBox(height: 16),
                           Text(localization.translate('no_recordings_yet'), style: GoogleFonts.robotoMono(color: Colors.white54)),
                         ],
                       ),
                    )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recordings.length,
                  itemBuilder: (context, index) {
                    String path = _recordings[index].path;
                    String fileName = path.split(Platform.pathSeparator).last;
                    String displayName = fileName.replaceAll('.aac', ''); // Hide extension
                    
                    final isSelected = _selectedFilePath == path;
                    final isPlaying = _isPlaying && _currentPlayingPath == path;
        
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : Colors.white.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: GestureDetector(
                          onTap: () => _togglePlayback(path),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isPlaying ? colorScheme.primary : Colors.black26,
                              shape: BoxShape.circle,
                              boxShadow: isPlaying ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ] : [],
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: isPlaying ? Colors.black : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: GoogleFonts.robotoMono(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                          color: const Color(0xFF1D1E33),
                          onSelected: (value) {
                            if (value == 'rename') {
                              _renameRecording(path);
                            } else if (value == 'delete') {
                              _deleteRecording(path);
                            }
                          },
                          itemBuilder: (context) => [
                             PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(localization.translate('rename'), style: GoogleFonts.outfit(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text(localization.translate('delete'), style: TextStyle(color: colorScheme.error, fontFamily: 'Outfit')),
                                ],
                              ),
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
        ),
      ),
    );
  }
}