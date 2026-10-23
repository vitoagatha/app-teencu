import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'room_chat.dart';

class MenuChat extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  
  final List<Map<String, String>> recommendedUsers = [
    {'name': 'INFJ', 'avatar': 'assets/avatars/infj.png'},
    {'name': 'ENTP', 'avatar': 'assets/avatars/entp.png'},
    {'name': 'ENFP', 'avatar': 'assets/avatars/enfp.png'},
    {'name': 'INTJ', 'avatar': 'assets/avatars/intj.png'},
  ];

  final List<Map<String, String>> chatList = [
    {'name': 'ENTP #001', 'message': 'How are you today?', 'time': '2 min ago'},
    {'name': 'INFJ #001', 'message': 'Have a good day 🌸', 'time': '2 min ago'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(500, 248, 55, 88),
        elevation: 0,
        title: Text(
          'Teencu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          // Background putih
          Container(
            color: Colors.white,
          ),
          // Konten utama
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian rekomendasi pengguna
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direkomendasikan untuk anda:',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: recommendedUsers.map((user) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundImage: AssetImage(user['avatar']!),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user['name']!,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Bagian daftar chat
              Expanded(
                child: Container(
                  color: Color.fromARGB(500, 248, 55, 88), // Background pink
                  child: ListView.builder(
                    itemCount: chatList.length,
                    itemBuilder: (context, index) {
                      final chat = chatList[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigasi ke Room Chat dengan parameter
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomChat(
                                userName: chat['name']!,
                                avatar: 'assets/avatars/${chat['name']!.split(' ')[0].toLowerCase()}.png',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage:
                                  AssetImage('assets/avatars/${chat['name']!.split(' ')[0].toLowerCase()}.png'),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chat['name']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        chat['message']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  chat['time']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
