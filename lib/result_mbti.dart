import 'package:flutter/material.dart';
import 'package:teencu/home.dart';
import 'package:teencu/menu_chat.dart';

class ResultMbti extends StatelessWidget {
  final String mbtiType; // Tipe MBTI (contoh: ENFP, INFJ)
  final String name; // Judul deskripsi (misalnya "The Idealist")
  final String description; // Deskripsi kepribadian
  final List<String> compatibleTypes; // Daftar kepribadian yang cocok

  const ResultMbti({
    Key? key,
    required this.mbtiType,
    required this.name,
    required this.description,
    required this.compatibleTypes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        elevation: 0,
        title: Text(
          'Hasil MBTI',
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
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
      ),
      body: Stack(
        children: [
          // Background putih di bagian atas
          Container(
            height: screenHeight * 0.3,
            color: Colors.white,
          ),

          // Konten utama
          Column(
            children: [
              SizedBox(height: 20),
              // Gambar/logo di atas
              Image.asset(
                "assets/teencu_logo.png", // Gambar/logo
                height: 80,
              ),

              const SizedBox(height: 20),

              // Expanded Container dengan latar belakang berwarna pink
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circle Avatar untuk MBTI Type (berisi gambar dari assets)
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.pink.shade100,
                          backgroundImage: AssetImage(
                            'assets/avatars/${mbtiType.toLowerCase()}.png', // Gambar sesuai MBTI
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Nama MBTI di bawah avatar
                        Text(
                          mbtiType,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Judul (diambil dari `name`)
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Deskripsi kepribadian
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 30),

                        // Kepribadian yang cocok
                        const Text(
                          "Kepribadian yang cocok dengan Anda:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Daftar kepribadian yang cocok (Circle Avatar)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: compatibleTypes.map((type) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.pink.shade200,
                                  backgroundImage: AssetImage(
                                    'assets/avatars/${type.toLowerCase()}.png', // Gambar sesuai MBTI
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  type,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 30),

                        // Tombol Chat dan Selesai
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Tombol Selesai
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => HomePage()), // Ganti dengan halaman tes MBTI Anda
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Selesai',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                              ),
                            ),
                            // Tombol Chat
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MenuChat()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Chat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
