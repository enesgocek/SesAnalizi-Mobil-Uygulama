import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_flags/country_flags.dart';
import 'recorder_page.dart';
import 'recordings_page.dart';
import 'localization_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showLanguagePanel() {
    final localization = LocalizationManager();
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1D1E33),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localization.translate('select_language'),
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400, // Limit height
                  child: ListView.separated(
                    itemCount: localization.supportedLanguages.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.1)),
                    itemBuilder: (context, index) {
                      String code = localization.supportedLanguages.keys.elementAt(index);
                      String name = localization.supportedLanguages[code]!;
                      String flagCode = localization.languageFlags[code]!;

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CountryFlag.fromCountryCode(
                            flagCode,
                            height: 32,
                            width: 48,
                          ),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: code == localization.languageCode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: code == localization.languageCode
                          ? const Icon(Icons.check_circle, color: Color(0xFF00E5FF))
                          : null,
                        onTap: () {
                          localization.setLanguage(code);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localization = LocalizationManager();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                Color(0xFF1F2633), // Soft spotlight
                Color(0xFF070B14), // Deep void
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      
                      // 1. High-Quality Visual (Glowing Icon)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 50,
                              spreadRadius: 10,
                            )
                          ],
                          border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: Icon(
                          Icons.mic_none_outlined, 
                          size: 64, 
                          color: colorScheme.primary
                        ),
                      ),
            
                      const SizedBox(height: 48),
            
                      // 2. Title
                      Text(
                        localization.translate('app_title'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4.0,
                          color: Colors.white,
                          shadows: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.5),
                              blurRadius: 20,
                            )
                          ]
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localization.translate('subtitle'),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white54,
                          letterSpacing: 2.0,
                        ),
                      ),
            
                      const Spacer(),
            
                      // 3. Simple Buttons
                      // Button 1: Start Analysis
                      _buildMainButton(
                        context,
                        label: localization.translate('start_analysis'),
                        icon: Icons.graphic_eq,
                        color: colorScheme.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RecorderPage()),
                          );
                        },
                      ),
            
                      const SizedBox(height: 20),
            
                      // Button 2: Recording Log
                      _buildSecondaryButton(
                        context,
                        label: localization.translate('record_book'),
                        icon: Icons.history_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RecordingsPage()),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
                // Language Settings Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _showLanguagePanel,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1E33), // Solid dark color (doughnut-like)
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.primary.withOpacity(0.5), width: 2),
                        boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                        ]
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(0), // Removed padding to fill the circle
                          child: CountryFlag.fromCountryCode(
                            localization.languageFlags[localization.languageCode]!,
                            height: 56,
                            width: 56, 
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          elevation: 10,
          shadowColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onTap,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
