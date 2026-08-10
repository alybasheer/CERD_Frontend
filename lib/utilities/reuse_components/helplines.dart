class Helpline {
  final String label;
  final String number;

  const Helpline({required this.label, required this.number});
}

const List<Helpline> kHelplines = [
  Helpline(label: 'Rescue 1122 (Emergency)', number: '1122'),
  Helpline(label: 'Police', number: '15'),
  Helpline(label: 'Fire Brigade', number: '16'),
  Helpline(label: 'Ambulance (Edhi)', number: '115'),
  Helpline(label: 'Women Helpline', number: '1739'),
];
