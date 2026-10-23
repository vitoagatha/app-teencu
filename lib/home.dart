import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teencu/expl_mbti.dart';
import 'package:teencu/leaderboard.dart';
import 'package:teencu/menu_chat.dart';
import 'package:teencu/profile_page.dart';

class HomePage extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String mbti = '';
  
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
            // Tombol Tes MBTI
            _buildButton(context, "Tes MBTI", Color.fromARGB(500, 248,55,88), () async {
              mbti = await getUserMbti();
                if (mbti == ''){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MbtiExplanationPage()),
                  );
                  return;
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Peringatan'),
                        content: Text('Apakah kamu ingin tes MBTI lagi?'),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.black),
                            onPressed: () {
                              Navigator.pop(context); // Menutup dialog
                            },
                            child: Text('Nggak dulu deh'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.black),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => MbtiExplanationPage()),
                              );
                            },
                            child: Text('Iya nih'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },),
            SizedBox(height: 16),
            // Tombol Chat
            _buildButton(context, "Chat", Color.fromARGB(500, 248,55,88), () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Peringatan'),
                    content: Text('Kamu belum mengisi tes MBTI. Silahkan tes terlebih dahulu untuk menggunakan fitur chat.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          return;
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MenuChat()),
              );
            }),
            SizedBox(height: 16),
            // Tombol Leaderboard
            _buildButton(context, "Leaderboard", Color.fromARGB(500, 248,55,88), () {
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
      BuildContext context, String text, Color color, VoidCallback onPressed) {
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

  Future<String> getUserMbti() async{
    DocumentSnapshot doc = await firestore.collection('users').doc(user!.uid).get();
    if (doc.exists && doc.data() != null) {
      mbti = doc.get('lastMbti') as String;
    }
    return mbti;
  }
}
