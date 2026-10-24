import '../model/mbti_question.dart';

// Stable IDs keep answers associated with their question when order changes.
const mbtiQuestions = <MbtiQuestion>[
  MbtiQuestion(
      id: 'q01',
      text:
          'Saya merasa lebih berenergi saat berada di acara sosial atau bersama banyak orang.',
      agreeWith: MbtiPreference.e),
  MbtiQuestion(
      id: 'q02',
      text:
          'Saya lebih suka menghabiskan waktu sendiri untuk menyegarkan pikiran.',
      agreeWith: MbtiPreference.i),
  MbtiQuestion(
      id: 'q03',
      text:
          'Saya suka berbicara untuk memecahkan masalah daripada merenungkannya dalam pikiran.',
      agreeWith: MbtiPreference.e),
  MbtiQuestion(
      id: 'q04',
      text:
          'Saya cenderung berbicara lebih banyak daripada mendengarkan dalam percakapan.',
      agreeWith: MbtiPreference.e),
  MbtiQuestion(
      id: 'q05',
      text: 'Saya merasa nyaman bekerja dalam kelompok besar.',
      agreeWith: MbtiPreference.e),
  MbtiQuestion(
      id: 'q06',
      text: 'Saya lebih suka detail yang konkret dibandingkan ide-ide abstrak.',
      agreeWith: MbtiPreference.s),
  MbtiQuestion(
      id: 'q07',
      text:
          'Saya fokus pada masa kini daripada memikirkan masa depan yang jauh.',
      agreeWith: MbtiPreference.s),
  MbtiQuestion(
      id: 'q08',
      text: 'Saya senang mengandalkan fakta daripada intuisi atau perasaan.',
      agreeWith: MbtiPreference.s),
  MbtiQuestion(
      id: 'q09',
      text:
          'Saya sering memperhatikan detail kecil yang sering dilewatkan orang lain.',
      agreeWith: MbtiPreference.s),
  MbtiQuestion(
      id: 'q10',
      text:
          'Saya lebih senang melihat "gambaran besar" daripada fokus pada detail kecil.',
      agreeWith: MbtiPreference.n),
  MbtiQuestion(
      id: 'q11',
      text: 'Saya membuat keputusan berdasarkan logika dan fakta, bukan emosi.',
      agreeWith: MbtiPreference.t),
  MbtiQuestion(
      id: 'q12',
      text:
          'Saya lebih peduli tentang keadilan daripada menjaga perasaan orang lain.',
      agreeWith: MbtiPreference.t),
  MbtiQuestion(
      id: 'q13',
      text:
          'Saya sering mempertimbangkan konsekuensi logis dalam setiap tindakan saya.',
      agreeWith: MbtiPreference.t),
  MbtiQuestion(
      id: 'q14',
      text:
          'Saya lebih memilih menyelesaikan masalah daripada memikirkan dampak emosionalnya.',
      agreeWith: MbtiPreference.t),
  MbtiQuestion(
      id: 'q15',
      text:
          'Saya cenderung mengambil keputusan dengan mempertimbangkan perasaan semua pihak.',
      agreeWith: MbtiPreference.f),
  MbtiQuestion(
      id: 'q16',
      text: 'Saya lebih suka merencanakan segalanya sebelumnya.',
      agreeWith: MbtiPreference.j),
  MbtiQuestion(
      id: 'q17',
      text: 'Saya merasa nyaman mengikuti jadwal dan struktur.',
      agreeWith: MbtiPreference.j),
  MbtiQuestion(
      id: 'q18',
      text: 'Saya lebih suka fleksibilitas daripada memiliki jadwal yang kaku.',
      agreeWith: MbtiPreference.p),
  MbtiQuestion(
      id: 'q19',
      text: 'Saya sering menunda pekerjaan hingga mendekati batas waktu.',
      agreeWith: MbtiPreference.p),
  MbtiQuestion(
      id: 'q20',
      text:
          'Saya senang mengambil keputusan cepat dan menyelesaikan tugas dengan cepat.',
      agreeWith: MbtiPreference.j),
];
