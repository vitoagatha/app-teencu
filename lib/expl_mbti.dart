import 'package:flutter/material.dart';
import 'package:teencu/mbti_cat.dart';

class MbtiExplanationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        elevation: 0,
        title: Text(
          'Apa itu Tes MBTI?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white
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
          // Background warna pink setengah layar
          Container(
            height: screenHeight * 0.3, // Mengisi 30% layar untuk header
            color: Colors.white,
          ),
          // Konten utama
          Column(
            children: [
              SizedBox(height: 20),
              // Gambar ilustrasi MBTI
              Image.asset(
                "assets/teencu_logo.png", // Logo Teencu di tengah
                height: 100,
              ),
              SizedBox(height: 20),
              // Bagian konten penjelasan
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apa itu Tes MBTI?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Tes MBTI adalah alat psikologi yang dirancang untuk membantu seseorang memahami kepribadian mereka berdasarkan teori psikologi Carl Jung. Tes ini mengelompokkan kepribadian ke dalam 16 tipe yang berbeda, berdasarkan kombinasi dari empat dimensi utama:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        _buildDimensionItem(
                          '1. Ekstrovert (E) vs. Introvert (I)',
                          'Menggambarkan bagaimana seseorang mendapatkan energi—dari interaksi sosial (Ekstrovert) atau dari waktu sendirian (Introvert).',
                        ),
                        _buildDimensionItem(
                          '2. Sensing (S) vs. Intuition (N)',
                          'Menggambarkan cara seseorang memproses informasi—berfokus pada fakta konkret dan detail (Sensing) atau pada pola dan gambaran besar (Intuition).',
                        ),
                        _buildDimensionItem(
                          '3. Thinking (T) vs. Feeling (F)',
                          'Menunjukkan bagaimana seseorang membuat keputusan—berdasarkan logika dan objektivitas (Thinking) atau pada nilai dan emosi (Feeling).',
                        ),
                        _buildDimensionItem(
                          '4. Judging (J) vs. Perceiving (P)',
                          'Menggambarkan gaya hidup seseorang—terorganisir dan terencana (Judging) atau fleksibel dan spontan (Perceiving).',
                        ),
                        SizedBox(height: 30),
                        // Tombol Selanjutnya
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigasi ke halaman berikutnya, misalnya tes MBTI
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MbtiCategoriesPage()), // Ganti dengan halaman tes MBTI Anda
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Selanjutnya',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                          ),
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

  // Widget untuk setiap dimensi MBTI
  Widget _buildDimensionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
