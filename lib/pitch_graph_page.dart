import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'localization_manager.dart';

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
        "frequencyRange": "261.6 - 880.0 Hz",
      },
      "MEZZO_SOPRANO": {
        "noteRange": "A3 - F5",
        "frequencyRange": "220.0 - 698.5 Hz",
      },
      "CONTRALTO": {
        "noteRange": "F3 - D5",
        "frequencyRange": "174.6 - 587.3 Hz",
      },
      "COUNTER_TENOR": {
        "noteRange": "G3 - E5",
        "frequencyRange": "196.0 - 659.3 Hz",
      },
      "TENOR": {
        "noteRange": "C3 - A4",
        "frequencyRange": "130.8 - 440.0 Hz",
      },
      "BARITONE": {
        "noteRange": "A2 - F4",
        "frequencyRange": "110.0 - 349.2 Hz",
      },
      "BASS": {
        "noteRange": "E2 - E4",
        "frequencyRange": "82.4 - 329.6 Hz",
      },
      "UNKNOWN": {
        "noteRange": "--",
        "frequencyRange": "--",
      },
    };
  }

  String normalizeVoiceType(String type) {
    if (type.isEmpty) return 'UNKNOWN';
    final cleaned = type.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.contains('soprano') && !cleaned.contains('mezzo')) return 'SOPRANO';
    if (cleaned.contains('mezzo')) return 'MEZZO_SOPRANO';
    if (cleaned.contains('contralto') || cleaned.contains('kontralto')) return 'CONTRALTO';
    if (cleaned.contains('counter')) return 'COUNTER_TENOR';
    if (cleaned.contains('tenor') || cleaned.contains('tenör')) return 'TENOR';
    if (cleaned.contains('bariton')) return 'BARITONE';
    if (cleaned.contains('bas')) return 'BASS';
    return 'UNKNOWN';
  }

  String getVoiceTypeKey(String normalizedType) {
    switch (normalizedType) {
      case 'SOPRANO': return 'voice_soprano';
      case 'MEZZO_SOPRANO': return 'voice_mezzo_soprano';
      case 'CONTRALTO': return 'voice_contralto';
      case 'COUNTER_TENOR': return 'voice_counter_tenor';
      case 'TENOR': return 'voice_tenor';
      case 'BARITONE': return 'voice_baritone';
      case 'BASS': return 'voice_bass';
      default: return 'voice_unknown';
    }
  }

  // Calculate dynamic intervals to prevent Y-axis overlap
  double _calculateInterval(double min, double max) {
    double range = max - min;
    if (range <= 0) return 50; 
    
    // Target roughly 5-6 labels
    double rawInterval = range / 5;
    
    // Round to nice numbers (10, 25, 50, 100, etc.)
    if (rawInterval < 10) return 10;
    if (rawInterval < 25) return 25;
    if (rawInterval < 50) return 50;
    if (rawInterval < 100) return 100;
    return (rawInterval / 100).ceil() * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final localization = LocalizationManager();
    final voiceRanges = getVoiceRanges();
    final normalizedVoiceType = normalizeVoiceType(voiceType);
    final voiceTypeKey = getVoiceTypeKey(normalizedVoiceType);
    final displayVoiceType = localization.translate(voiceTypeKey);
    
    final Map<String, String> currentRange =
        voiceRanges[normalizedVoiceType] ?? voiceRanges["UNKNOWN"]!;
    final colorScheme = Theme.of(context).colorScheme;

    Color typeColor = colorScheme.primary; 
    if (normalizedVoiceType == 'SOPRANO' || normalizedVoiceType == 'MEZZO_SOPRANO' || normalizedVoiceType == 'CONTRALTO') {
       typeColor = const Color(0xFFD500F9);
    } else if (normalizedVoiceType == 'UNKNOWN') {
       typeColor = Colors.grey;
    }

    // Determine Min/Max for dynamic scaling
    double minPitch = 0;
    double maxPitch = 500;
    if (pitchSeries.isNotEmpty) {
      minPitch = pitchSeries.reduce(math.min);
      maxPitch = pitchSeries.reduce(math.max);
      // Add padding
      minPitch = (minPitch * 0.9).clamp(0, double.infinity);
      maxPitch = maxPitch * 1.1;
    }
    double interval = _calculateInterval(minPitch, maxPitch);


    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          localization.translate('pitch_analysis'),
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
         decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.3,
              colors: [
                Color(0xFF1A1F38),
                Color(0xFF0A0E21),
              ],
            ),
          ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Signature Voice Type Card (Always Visible)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1E33).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: typeColor.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                           boxShadow: [
                            BoxShadow(
                              color: typeColor.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(Icons.graphic_eq, color: typeColor, size: 32),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localization.translate('your_voice_type'),
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 14,
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          displayVoiceType,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: typeColor.withOpacity(0.6),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: Colors.black.withOpacity(0.3),
                           borderRadius: BorderRadius.circular(16),
                         ),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatItem(localization.translate('frequency'), "${averagePitch.toStringAsFixed(1)} Hz", typeColor)),
                            Container(width: 1, height: 40, color: Colors.white10),
                            Expanded(child: _buildStatItem(localization.translate('duration'), _formatTime(processingTime), Colors.white)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
        
                const SizedBox(height: 24),

                // 2. Collapsible Detailed Analysis Blog
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true, // Default open
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white54,
                    title: Center(
                      child: Text(
                        localization.translate('detailed_analysis'),
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    children: [
                      const SizedBox(height: 16),
                      // Range Info Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRangeRowWithBar(localization.translate('note_range'), currentRange['noteRange']!, 0.7, colorScheme.secondary),
                            const SizedBox(height: 16),
                            _buildRangeRowWithBar(localization.translate('frequency_range'), currentRange['frequencyRange']!, 0.5, colorScheme.primary),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Pitch Progression Header
                      Center(
                        child: Text(
                          localization.translate('pitch_progression'),
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Graph Card
                      Container(
                        height: 250,
                        padding: const EdgeInsets.fromLTRB(16, 24, 24, 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151828),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: pitchSeries.isEmpty 
                          ? Center(child: Text(localization.translate('no_data'), style: GoogleFonts.robotoMono(color: Colors.white54)))
                          : LineChart(
                            LineChartData(
                              minY: minPitch,
                              maxY: maxPitch,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: interval,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withOpacity(0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 45, // Slightly increased for 3-digit numbers
                                    interval: interval,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: GoogleFonts.robotoMono(color: Colors.white30, fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _createSpots(pitchSeries),
                                  isCurved: true,
                                  curveSmoothness: 0.2,
                                  color: typeColor,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        typeColor.withOpacity(0.4),
                                        typeColor.withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBgColor: const Color(0xFF2A2D3E),
                                  tooltipRoundedRadius: 8,
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      return LineTooltipItem(
                                        "${spot.y.toStringAsFixed(1)} Hz",
                                        GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String raw) {
    if (raw.contains('.')) {
      return "${raw.split('.')[1].substring(0, 3)}ms";
    }
    return raw;
  }

  List<FlSpot> _createSpots(List<double> data) {
    List<FlSpot> spots = [];
    int step = data.length > 100 ? data.length ~/ 100 : 1;
    for (int i = 0; i < data.length; i+= step) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }
    return spots;
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.robotoMono(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600
          ),
        ),
      ],
    );
  }

  Widget _buildRangeRowWithBar(String label, String value, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54, letterSpacing: 1.0)),
            const SizedBox(width: 8), 
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value, 
                  textAlign: TextAlign.end,
                  style: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 6, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(
              widthFactor: 1.0, 
              child: Container(
                height: 6, 
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withOpacity(0.5), color]),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, spreadRadius: 0)]
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
