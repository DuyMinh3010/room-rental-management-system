String money(String? value) {
  final amount = int.tryParse(value ?? '') ?? 0;
  return '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
}
