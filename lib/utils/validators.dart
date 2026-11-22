String? validateEmail(String? value, {bool required = true}) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return required ? 'Vui lòng nhập email' : null;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
    return 'Email không hợp lệ';
  }
  return null;
}

String? validateVietnamesePhone(String? value, {bool required = true}) {
  final text = (value ?? '').replaceAll(RegExp(r'[\s().-]'), '');
  if (text.isEmpty) {
    return required ? 'Vui lòng nhập số điện thoại' : null;
  }
  final normalized = text.startsWith('+') ? text.substring(1) : text;
  if (!RegExp(r'^(?:0|84)[35789]\d{8}$').hasMatch(normalized)) {
    return 'Số điện thoại phải là số di động Việt Nam hợp lệ';
  }
  return null;
}

String? validateIdentity(String? value, {bool required = false}) {
  final text = (value ?? '').replaceAll(RegExp(r'\s'), '');
  if (text.isEmpty) return required ? 'Vui lòng nhập CCCD/Passport' : null;
  if (RegExp(r'^(?:\d{9}|\d{12})$').hasMatch(text)) return null;
  if (RegExp(r'^[A-Za-z][A-Za-z0-9]{6,8}$').hasMatch(text)) return null;
  return 'CCCD phải có 9 hoặc 12 chữ số; Passport cần 7-9 ký tự';
}
