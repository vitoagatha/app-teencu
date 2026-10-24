enum MbtiDimension {
  ei('E', 'I'),
  sn('S', 'N'),
  tf('T', 'F'),
  jp('J', 'P');

  const MbtiDimension(this.first, this.second);

  final String first;
  final String second;
  String get label => '$first/$second';
}

enum MbtiPreference {
  e(MbtiDimension.ei, 1),
  i(MbtiDimension.ei, -1),
  s(MbtiDimension.sn, 1),
  n(MbtiDimension.sn, -1),
  t(MbtiDimension.tf, 1),
  f(MbtiDimension.tf, -1),
  j(MbtiDimension.jp, 1),
  p(MbtiDimension.jp, -1);

  const MbtiPreference(this.dimension, this.direction);

  final MbtiDimension dimension;
  final int direction;
}

class MbtiQuestion {
  const MbtiQuestion({
    required this.id,
    required this.text,
    required this.agreeWith,
  });

  final String id;
  final String text;
  // The preference supported by agreeing with the statement.
  final MbtiPreference agreeWith;
  MbtiDimension get dimension => agreeWith.dimension;
}
