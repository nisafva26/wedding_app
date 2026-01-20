String normalizePhone(String phone) {
  // remove spaces, hyphens, brackets, dots
  return phone.replaceAll(RegExp(r'[^\d\+]'), '');
}
