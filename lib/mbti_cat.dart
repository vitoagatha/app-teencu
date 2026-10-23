import 'package:flutter/material.dart';
import 'package:teencu/question_mbti.dart';

class MbtiCategoriesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        elevation: 0,
        title: Text(
          'Golongan MBTI',
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
      body: Column(
        children: [
          // Bagian atas dengan latar belakang putih
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Teencu
                Image.asset(
                  'assets/teencu_logo.png',
                  height: 150, // Sesuaikan ukuran sesuai kebutuhan
                ),
              ],
            ),
          ),
          // Bagian bawah untuk konten utama
          Expanded(
            child: Container(
              color: Colors.pink, // Latar belakang pink
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    // Teks Judul
                    Text(
                      '16 Golongan MBTI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Deskripsi
                    Text(
                      'Mulai tes untuk menemukan avatar yang sesuai dengan hasil tes MBTI mu !!!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Grid Avatar MBTI
                    Expanded(
                      child: GridView.builder(
                        itemCount: 16, // Total golongan MBTI
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // 4 kolom
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 16,
                        ),
                        itemBuilder: (context, index) {
                          // Daftar nama MBTI
                          final mbtiTypes = [
                            'ISTJ', 'ISFJ', 'INFJ', 'INTJ',
                            'ISTP', 'ISFP', 'INFP', 'INTP',
                            'ESTP', 'ESFP', 'ENFP', 'ENTP',
                            'ESTJ', 'ESFJ', 'ENFJ', 'ENTJ',
                          ];

                          return Column(
                            children: [
                              // Avatar MBTI
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: AssetImage(
                                  'assets/avatars/${mbtiTypes[index].toLowerCase()}.png', // Ganti sesuai nama file
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Label MBTI
                              Text(
                                mbtiTypes[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tombol Mulai Tes
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  QuestionMbti()), // Ganti dengan halaman tes MBTI Anda
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Mulai Tes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
