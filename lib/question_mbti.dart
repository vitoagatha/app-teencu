import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teencu/model/mbti.dart';
import 'package:teencu/result_mbti.dart';

class QuestionMbti extends StatefulWidget {

  @override
  _QuestionMbtiState createState() => _QuestionMbtiState();
}

class _QuestionMbtiState extends State<QuestionMbti> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  int? selectedRating; // Variabel untuk menyimpan nilai rating pengguna
  final List<String> questions = [
    // Ekstrovert (E) vs Introvert (I)
    "Saya merasa lebih berenergi saat berada di acara sosial atau bersama banyak orang.",
    "Saya lebih suka menghabiskan waktu sendiri untuk menyegarkan pikiran.",
    "Saya suka berbicara untuk memecahkan masalah daripada merenungkannya dalam pikiran.",
    "Saya cenderung berbicara lebih banyak daripada mendengarkan dalam percakapan.",
    "Saya merasa nyaman bekerja dalam kelompok besar.",
    // Sensing (S) vs Intuition (I)
    "Saya lebih suka detail yang konkret dibandingkan ide-ide abstrak.",
    "Saya fokus pada masa kini daripada memikirkan masa depan yang jauh.",
    "Saya senang mengandalkan fakta daripada intuisi atau perasaan.",
    "Saya sering memperhatikan detail kecil yang sering dilewatkan orang lain.",
    "Saya lebih senang melihat \"gambaran besar\" daripada fokus pada detail kecil.",
    // Thinking (T) vs Feeling (F)
    "Saya membuat keputusan berdasarkan logika dan fakta, bukan emosi.",
    "Saya lebih peduli tentang keadilan daripada menjaga perasaan orang lain.",
    "Saya sering mempertimbangkan konsekuensi logis dalam setiap tindakan saya.",
    "Saya lebih memilih menyelesaikan masalah daripada memikirkan dampak emosionalnya.",
    "Saya cenderung mengambil keputusan dengan mempertimbangkan perasaan semua pihak.",
    // Judging (J) vs Perceiving (P)
    "Saya lebih suka merencanakan segalanya sebelumnya.",
    "Saya merasa nyaman mengikuti jadwal dan struktur.",
    "Saya lebih suka fleksibilitas daripada memiliki jadwal yang kaku.",
    "Saya sering menunda pekerjaan hingga mendekati batas waktu.",
    "Saya senang mengambil keputusan cepat dan menyelesaikan tugas dengan cepat.",
  ];

  int currentQuestionIndex = 0; // Pertanyaan yang ditampilkan saat ini
  Map<int, int> answers = {}; // Menyimpan jawaban untuk setiap pertanyaan

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        elevation: 0,
        title: const Text(
          'Pertanyaan MBTI',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              // Logo Teencu di tengah
              Center(
                child: Image.asset(
                  "assets/teencu_logo.png",
                  height: 80,
                ),
              ),
              // Progress bar
              LinearProgressIndicator(
                value: (currentQuestionIndex + 1) / questions.length,
                backgroundColor: Colors.grey.shade300,
                color: Colors.pink,
              ),
              const SizedBox(height: 20),

              // Pertanyaan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  questions[currentQuestionIndex],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Pilihan Jawaban (Tombol)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: List.generate(5, (index) {
                      final ratings = [
                        "Sangat Tidak Setuju",
                        "Tidak Setuju",
                        "Netral",
                        "Setuju",
                        "Sangat Setuju"
                      ];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          width: double.infinity, // Tombol melebar sesuai layar
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: answers[currentQuestionIndex] ==
                                  index + 1
                                  ? Colors.pink
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12), // Tinggi tombol seragam
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                  color: Colors.pink,
                                  width: 2,
                                ),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                answers[currentQuestionIndex] = index + 1;
                              });
                            },
                            child: Text(
                              ratings[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: answers[currentQuestionIndex] ==
                                    index + 1
                                    ? Colors.white
                                    : Colors.pink,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Navigasi di bagian bawah
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: currentQuestionIndex > 0
                          ? () {
                        setState(() {
                          // Kembali ke pertanyaan sebelumnya
                          currentQuestionIndex--;
                          selectedRating = null;
                        });
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentQuestionIndex > 0
                            ? Colors.pink
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Sebelumnya",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: answers[currentQuestionIndex] != null
                          ? () async {
                        if (currentQuestionIndex ==
                            questions.length - 1) {
                          String mbtiResult = calculateMBTI(answers);
                          MBTIType? data = mbtiData(mbtiResult);
                          String type = data!.mbtiType;
                          String name = data.name;
                          String desc = data.description;
                          List<String> comp = data.compatibleTypes;
                          String uid = user!.uid;
                          await firestore.collection('users').doc(uid).update({
                            'lastMbti': type,
                            'lastMbtiDate': FieldValue.serverTimestamp(),
                          });
                          Navigator.push(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResultMbti(
                                mbtiType: type,
                                name: name,
                                description: desc,
                                compatibleTypes: comp,
                              ),
                            ),
                          );
                        } else {
                          // Pindah ke pertanyaan berikutnya
                          setState(() {
                            currentQuestionIndex++;
                            selectedRating = null;
                          });
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: answers[currentQuestionIndex] != null
                            ? Colors.pink
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        currentQuestionIndex < questions.length - 1
                            ? "Selanjutnya"
                            : "Selesai",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  String calculateMBTI(Map<int, int> answers) {
    // Menyimpan skor untuk masing-masing dimensi
    int E = 0, I = 0, S = 0, N = 0, T = 0, F = 0, J = 0, P = 0;

    // Ekstrovert (E) vs Introvert (I) - Indeks 0, 1, 2, 3, 4
    if (answers[0]! > 3) {
      E++;
    } else {
      I++;
    }
    if (answers[1]! > 3) {
      E++;
    } else {
      I++;
    }
    if (answers[2]! > 3) {
      I++;
    } else {
      E++;
    }
    if (answers[3]! > 3) {
      E++;
    } else {
      I++;
    }
    if (answers[4]! > 3) {
      E++;
    } else {
      I++;
    }

    // Sensing (S) vs Intuition (N) - Indeks 5, 6, 7, 8, 9
    if (answers[5]! <= 3) {
      S++;
    } else {
      N++;
    }
    if (answers[6]! <= 3) {
      S++;
    } else {
      N++;
    }
    if (answers[7]! <= 3) {
      S++;
    } else {
      N++;
    }
    if (answers[8]! <= 3) {
      S++;
    } else {
      N++;
    }
    if (answers[9]! <= 3) {
      S++;
    } else {
      N++;
    }

    // Thinking (T) vs Feeling (F) - Indeks 10, 11, 12, 13, 14
    if (answers[10]! <= 3) {
      T++;
    } else {
      F++;
    }
    if (answers[11]! <= 3) {
      T++;
    } else {
      F++;
    }
    if (answers[12]! <= 3) {
      T++;
    } else {
      F++;
    }
    if (answers[13]! <= 3) {
      T++;
    } else {
      F++;
    }
    if (answers[14]! <= 3) {
      F++;
    } else {
      T++;
    }

    // Judging (J) vs Perceiving (P) - Indeks 15, 16, 17, 18, 19
    if (answers[15]! <= 3) {
      J++;
    } else {
      P++;
    }
    if (answers[16]! <= 3) {
      J++;
    } else {
      P++;
    }
    if (answers[17]! <= 3) {
      P++;
    } else {
      J++;
    }
    if (answers[18]! <= 3) {
      J++;
    } else {
      P++;
    }
    if (answers[19]! <= 3) {
      P++;
    } else {
      J++;
    }

    // Tentukan hasil MBTI berdasarkan perbandingan skor
    String result = '';
    result += (E > I) ? 'E' : 'I';
    result += (S > N) ? 'S' : 'N';
    result += (T > F) ? 'T' : 'F';
    result += (J > P) ? 'J' : 'P';

    return result;
  }

  MBTIType? mbtiData(String name){
    // ignore: unused_local_variable
    Map<String, MBTIType> mbtiDescriptions = {
      "ESTP": MBTIType(
        mbtiType: "ESTP",
        name: "ESTP (The Entrepreneur)",
        description: "ESTP adalah individu yang suka beraksi dan cepat dalam membuat keputusan. "
            "Mereka cenderung praktis dan sangat terampil dalam menangani situasi darurat.",
        compatibleTypes: ["ISTJ", "ISFJ", "ESTJ", "ESFP"],
      ),
      "ISTP": MBTIType(
        mbtiType: "ISTP",
        name: "ISTP (The Virtuoso)",
        description: "ISTP dikenal dengan pendekatan praktis dan logis terhadap masalah. "
            "Mereka lebih suka menyelesaikan masalah secara langsung dan memiliki keterampilan teknis yang luar biasa.",
        compatibleTypes: ["ESTP", "ESFP", "ISTJ", "INTJ"],
      ),
      "ESFP": MBTIType(
        mbtiType: "ESFP",
        name: "ESFP (The Entertainer)",
        description: "ESFP adalah individu yang penuh semangat, suka bersenang-senang, dan sangat sosial. "
            "Mereka menikmati hidup dan sangat peduli pada kebahagiaan orang lain.",
        compatibleTypes: ["ISFP", "ESTP", "ESFJ", "ENFJ"],
      ),
      "ISFP": MBTIType(
        mbtiType: "ISFP",
        name: "ISFP (The Adventurer)",
        description: "ISFP adalah pribadi yang sangat kreatif, dan mereka lebih suka menjalani hidup sesuai dengan nilai-nilai pribadi mereka. "
            "Mereka cenderung lebih tenang dan sering berfokus pada keindahan sekitar mereka.",
        compatibleTypes: ["ESFP", "INFP", "ISFJ"],
      ),
      "ESTJ": MBTIType(
        mbtiType: "ESTJ",
        name: "ESTJ (The Executive)",
        description: "ESTJ sangat terorganisir, terstruktur, dan berorientasi pada detail. "
            "Mereka sangat menghargai tradisi dan ingin memastikan bahwa segala sesuatunya berjalan dengan efisien.",
        compatibleTypes: ["ISTJ", "ISFJ", "ESFJ", "ENTJ"],
      ),
      "ISTJ": MBTIType(
        mbtiType: "ISTJ",
        name: "ISTJ (The Logistician)",
        description: "ISTJ adalah tipe yang sangat bertanggung jawab, disiplin, dan selalu mengutamakan pekerjaan yang sistematis dan terstruktur. "
            "Mereka sangat dapat diandalkan.",
        compatibleTypes: ["ESTJ", "ISFJ", "ENTJ"],
      ),
      "ESFJ": MBTIType(
        mbtiType: "ESFJ",
        name: "ESFJ (The Consul)",
        description: "ESFJ adalah tipe yang sangat peduli dan selalu berusaha membuat orang lain merasa nyaman. "
            "Mereka sangat sosial dan senang berinteraksi dengan banyak orang.",
        compatibleTypes: ["ISFJ", "ESTJ", "ENFJ"],
      ),
      "ISFJ": MBTIType(
        mbtiType: "ISFJ",
        name: "ISFJ (The Defender)",
        description: "ISFJ sangat peduli dengan orang lain, sangat perhatian, dan terorganisir. "
            "Mereka sering menjadi pendukung bagi teman-teman dan keluarga mereka.",
        compatibleTypes: ["ESFJ", "ESTJ", "ISFP"],
      ),
      "ENFP": MBTIType(
        mbtiType: "ENFP",
        name: "ENFP (The Inspirer)",
        description: "ENFP adalah individu yang antusias, bersemangat, dan sangat kreatif. "
            "Mereka memiliki banyak ide baru dan sering kali menginspirasi orang di sekitar mereka.",
        compatibleTypes: ["INFJ", "ENFJ", "INFP"],
      ),
      "INFP": MBTIType(
        mbtiType: "INFP",
        name: "INFP (The Mediator)",
        description: "INFP adalah tipe yang sangat idealis, empatik, dan lebih suka mengikuti naluri mereka daripada aturan. "
            "Mereka mencari makna dalam segala hal dan berusaha membuat dunia menjadi tempat yang lebih baik.",
        compatibleTypes: ["ENFJ", "ENFP", "ISFP"],
      ),
      "ENFJ": MBTIType(
        mbtiType: "ENFJ",
        name: "ENFJ (The Protagonist)",
        description: "ENFJ adalah seorang pemimpin yang berfokus pada orang lain dan sangat peduli dengan kebutuhan mereka. "
            "Mereka selalu berusaha menginspirasi orang lain untuk menjadi versi terbaik dari diri mereka.",
        compatibleTypes: ["INFJ", "ENFP", "INFP"],
      ),
      "INFJ": MBTIType(
        mbtiType: "INFJ",
        name: "INFJ (The Advocate)",
        description: "INFJ adalah pemimpi yang penuh kasih dan memiliki visi tentang dunia yang lebih baik. "
            "Mereka sangat berorientasi pada tujuan dan memiliki kemampuan untuk membantu orang lain mencapai potensi terbaik mereka.",
        compatibleTypes: ["ENFP", "ENFJ", "INFP"],
      ),
      "ENTP": MBTIType(
        mbtiType: "ENTP",
        name: "ENTP (The Debater)",
        description: "ENTP adalah seorang pendebat yang sangat cerdas dan kreatif. "
            "Mereka suka menganalisis ide-ide dan memikirkan cara-cara baru untuk memecahkan masalah.",
        compatibleTypes: ["INFJ", "ENFP", "INTP"],
      ),
      "INTP": MBTIType(
        mbtiType: "INTP",
        name: "INTP (The Thinker)",
        description: "INTP adalah tipe pemikir yang cerdas dan sangat logis. "
            "Mereka suka mengeksplorasi ide-ide baru dan berusaha memahami dunia dengan cara yang lebih mendalam.",
        compatibleTypes: ["ENTP", "ENTJ", "INTJ"],
      ),
      "ENTJ": MBTIType(
        mbtiType: "ENTJ",
        name: "ENTJ (The Commander)",
        description: "ENTJ adalah pemimpin alami yang sangat berorientasi pada tujuan dan sangat terorganisir. "
            "Mereka memiliki visi yang jelas dan berusaha mencapai tujuan dengan cara yang efisien dan tegas.",
        compatibleTypes: ["INTJ", "ENTP", "ESTJ"],
      ),
      "INTJ": MBTIType(
        mbtiType: "INTJ",
        name: "INTJ (The Architect)",
        description: "INTJ adalah seorang visioner yang sangat strategis. "
            "Mereka berfokus pada pencapaian tujuan jangka panjang dan sangat analitis dalam pendekatan mereka.",
        compatibleTypes: ["ENTP", "ENTJ", "INTP"],
      ),
    };
    return mbtiDescriptions[name];
  }
}
