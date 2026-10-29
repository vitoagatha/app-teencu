import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teencu/expl_mbti.dart';
import 'package:teencu/leaderboard.dart';
import 'package:teencu/menu_chat.dart';
import 'package:teencu/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.loadMbti, this.chatBuilder});

  final Future<String> Function()? loadMbti;
  final WidgetBuilder? chatBuilder;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _checkingMbti = false;
  bool _loadingMbti = false;

  Future<void> _openMbtiFeature({required bool chat}) async {
    if (_checkingMbti) return;
    setState(() {
      _checkingMbti = true;
      _loadingMbti = true;
    });
    try {
      final mbti = await (widget.loadMbti ?? getUserMbti)()
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() => _loadingMbti = false);
      if (chat) {
        if (mbti.isEmpty) {
          await showDialog<void>(
            context: context,
            useRootNavigator: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Peringatan'),
              content: const Text(
                  'Kamu belum mengisi tes MBTI. Silahkan tes terlebih dahulu untuk menggunakan fitur chat.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: widget.chatBuilder ?? (_) => MenuChat(),
        ));
      } else {
        if (mbti.isNotEmpty) {
          final repeat = await showDialog<bool>(
            context: context,
            useRootNavigator: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Peringatan'),
              content: const Text('Apakah kamu ingin tes MBTI lagi?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Nggak dulu deh'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Iya nih'),
                ),
              ],
            ),
          );
          if (!mounted || repeat != true) return;
        }
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => MbtiExplanationPage(),
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Status MBTI belum dapat dimuat. Periksa koneksi lalu coba lagi.'),
      ));
    } finally {
      if (mounted) {
        setState(() {
          _checkingMbti = false;
          _loadingMbti = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false, // Menghapus ikon default di kiri
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 40), // Placeholder kosong untuk simetri
              Image.asset(
                "assets/teencu_logo.png", // Logo Teencu di tengah
                height: 100,
              ),
              GestureDetector(
                onTap: () {
                  // Navigasi ke halaman ProfilePage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      AssetImage("assets/icons/profile_avatar.png"),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Image.asset(
              "assets/lightbulb.png",
              height: 200,
            ),
            SizedBox(height: 20),
            Text(
              "Apa yang Ingin kamu lakukan ?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            // Read the saved result on each tap, including after a new test.
            _buildButton(
                context,
                "Tes MBTI",
                const Color.fromARGB(255, 248, 55, 88),
                _checkingMbti ? null : () => _openMbtiFeature(chat: false)),
            const SizedBox(height: 16),
            _buildButton(
                context,
                "Chat",
                const Color.fromARGB(255, 248, 55, 88),
                _checkingMbti ? null : () => _openMbtiFeature(chat: true)),
            if (_loadingMbti) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            // Tombol Leaderboard
            _buildButton(
                context, "Leaderboard", Color.fromARGB(500, 248, 55, 88), () {
              // Navigasi ke halaman Leaderboard
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Leaderboard()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String text, Color color, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Future<String> getUserMbti() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No active session');
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));
    final data = doc.data();
    if (data == null) throw StateError('Profile missing');
    return data['lastMbti'] as String? ?? '';
  }
}
