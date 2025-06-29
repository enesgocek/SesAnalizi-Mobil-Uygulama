import 'dart:io'; // Eklendi
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'login_page.dart';
import 'home_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final uid = user.uid;

        await FirebaseFirestore.instance.collection('users').doc(uid).delete();

        final appDir = await getApplicationDocumentsDirectory();
        final userDir = Directory('${appDir.path}/$uid');
        if (await userDir.exists()) {
          await userDir.delete(recursive: true);
        }

        await user.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hesabınız ve tüm verileriniz silindi.")),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        String message = "Hesap silinirken hata oluştu.";
        if (e.code == 'requires-recent-login') {
          message =
          "Lütfen güvenlik nedeniyle tekrar giriş yapın ve ardından hesabınızı silin.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Beklenmeyen bir hata oluştu.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                          (Route<dynamic> route) => false,
                    );
                  },
                ),
                const SizedBox(width: 10),
                Text(
                  "Profil",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            user?.email ?? 'Email bilinmiyor',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          const Icon(Icons.music_note, size: 50, color: Colors.deepPurple),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(
              "Çıkış Yap",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Color(0xFFF4E9FF),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: Text(
              "Hesabımı Sil",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Hesabı Sil"),
                  content: const Text(
                      "Bu işlem geri alınamaz. Hesabınızı silmek istediğinize emin misiniz?"),
                  actions: [
                    TextButton(
                      child: const Text("İptal"),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: const Text("Evet, Sil"),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                _deleteAccount(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
