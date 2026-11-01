class RingSizeEntry {
  const RingSizeEntry({
    required this.diameterMm,
    required this.usSize,
    required this.euSize,
    required this.ukSize,
    required this.jpSize,
    required this.inSize,
  });

  final double diameterMm;
  final String usSize;
  final String euSize;
  final String ukSize;
  final String jpSize;
  final String inSize;
}

const List<RingSizeEntry> ringSizeChart = [
  RingSizeEntry(diameterMm: 14.1, usSize: '3',   euSize: '44', ukSize: 'F', jpSize: '3',  inSize: '1'),
  RingSizeEntry(diameterMm: 14.5, usSize: '3.5', euSize: '45', ukSize: 'G', jpSize: '5',  inSize: '3'),
  RingSizeEntry(diameterMm: 14.9, usSize: '4',   euSize: '47', ukSize: 'H', jpSize: '7',  inSize: '5'),
  RingSizeEntry(diameterMm: 15.3, usSize: '4.5', euSize: '48', ukSize: 'I', jpSize: '8',  inSize: '6'),
  RingSizeEntry(diameterMm: 15.7, usSize: '5',   euSize: '49', ukSize: 'J', jpSize: '9',  inSize: '7'),
  RingSizeEntry(diameterMm: 16.1, usSize: '5.5', euSize: '51', ukSize: 'K', jpSize: '10', inSize: '8'),
  RingSizeEntry(diameterMm: 16.5, usSize: '6',   euSize: '52', ukSize: 'L', jpSize: '12', inSize: '10'),
  RingSizeEntry(diameterMm: 16.9, usSize: '6.5', euSize: '53', ukSize: 'M', jpSize: '13', inSize: '11'),
  RingSizeEntry(diameterMm: 17.3, usSize: '7',   euSize: '55', ukSize: 'N', jpSize: '14', inSize: '13'),
  RingSizeEntry(diameterMm: 17.7, usSize: '7.5', euSize: '56', ukSize: 'O', jpSize: '15', inSize: '14'),
  RingSizeEntry(diameterMm: 18.1, usSize: '8',   euSize: '57', ukSize: 'P', jpSize: '16', inSize: '15'),
  RingSizeEntry(diameterMm: 18.5, usSize: '8.5', euSize: '59', ukSize: 'Q', jpSize: '18', inSize: '17'),
  RingSizeEntry(diameterMm: 19.0, usSize: '9',   euSize: '60', ukSize: 'R', jpSize: '19', inSize: '18'),
  RingSizeEntry(diameterMm: 19.4, usSize: '9.5', euSize: '61', ukSize: 'S', jpSize: '20', inSize: '19'),
  RingSizeEntry(diameterMm: 19.8, usSize: '10',  euSize: '62', ukSize: 'T', jpSize: '21', inSize: '20'),
  RingSizeEntry(diameterMm: 20.2, usSize: '10.5',euSize: '64', ukSize: 'U', jpSize: '22', inSize: '21'),
  RingSizeEntry(diameterMm: 20.6, usSize: '11',  euSize: '65', ukSize: 'V', jpSize: '24', inSize: '23'),
  RingSizeEntry(diameterMm: 21.0, usSize: '11.5',euSize: '67', ukSize: 'W', jpSize: '25', inSize: '25'),
  RingSizeEntry(diameterMm: 21.4, usSize: '12',  euSize: '68', ukSize: 'X', jpSize: '26', inSize: '26'),
];

RingSizeEntry? findSizeByDiameter(double diameterMm) {
  if (ringSizeChart.isEmpty) return null;
  return ringSizeChart.reduce((a, b) =>
    (a.diameterMm - diameterMm).abs() < (b.diameterMm - diameterMm).abs() ? a : b);
}
