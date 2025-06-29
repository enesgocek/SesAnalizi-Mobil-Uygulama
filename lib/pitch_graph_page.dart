import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PitchGraphPage extends StatelessWidget {
  final List<double> pitchSeries;
  final String voiceType;
  final dynamic averagePitch;
  final String processingTime;

  const PitchGraphPage({
    super.key,
    required this.pitchSeries,
    required this.voiceType,
    required this.averagePitch,
    required this.processingTime,
  });

  Map<String, Map<String, String>> getVoiceRanges() {
    return {
      "SOPRANO": {
        "noteRange": "C4 - A5",
        "frequencyRange": "261.63 Hz - 880.00 Hz",
      },
      "MEZZO_SOPRANO": {
        "noteRange": "A3 - F5",
        "frequencyRange": "220.00 Hz - 698.46 Hz",
      },
      "CONTRALTO": {
        "noteRange": "F3 - D5",
        "frequencyRange": "174.61 Hz - 587.33 Hz",
      },
      "COUNTER_TENOR": {
        "noteRange": "G3 - E5",
        "frequencyRange": "196.00 Hz - 659.26 Hz",
      },
      "TENOR": {
        "noteRange": "C3 - A4",
        "frequencyRange": "130.81 Hz - 440.00 Hz",
      },
      "BARITONE": {
        "noteRange": "A2 - F4",
        "frequencyRange": "110.00 Hz - 349.23 Hz",
      },
      "BASS": {
        "noteRange": "E2 - E4",
        "frequencyRange": "82.41 Hz - 329.63 Hz",
      },
      "UNKNOWN": {
        "noteRange": "Bilinmiyor",
        "frequencyRange": "Bilinmiyor",
      },
    };
  }

  String normalizeVoiceType(String type) {
    final cleaned = type.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
    switch (cleaned) {
      case 'soprano':
        return 'SOPRANO';
      case 'mezzosoprano':
        return 'MEZZO_SOPRANO';
      case 'kontralto':
      case 'contralto':
        return 'CONTRALTO';
      case 'countertenor':
      case 'countertenör':
        return 'COUNTER_TENOR';
      case 'tenor':
      case 'tenör':
        return 'TENOR';
      case 'bariton':
      case 'baritone':
        return 'BARITONE';
      case 'bas':
      case 'bass':
        return 'BASS';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceRanges = getVoiceRanges();
    final normalizedVoiceType = normalizeVoiceType(voiceType);
    final Map<String, String> currentRange =
        voiceRanges[normalizedVoiceType] ?? voiceRanges["UNKNOWN"]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pitch Analizi Özeti"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🎧 Detaylı Ses Özeti",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🎙 Ses Tipi: $voiceType",
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "📈 Ortalama Pitch: ${averagePitch.toStringAsFixed(2)} Hz",
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "⏱ İşlem Süresi: $processingTime",
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.deepPurple.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🔊 $voiceType Ses Aralığı",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "🎼 Nota Aralığı: ${currentRange['noteRange']}",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "📊 Frekans Aralığı: ${currentRange['frequencyRange']}",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ],
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
