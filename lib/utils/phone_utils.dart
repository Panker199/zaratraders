class PhoneUtils {
  static const String countryCode = '+92';
  static const int minDigitsAfterCode = 10;

  static String format(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+92') && cleaned.length == 13) {
      return cleaned;
    }
    if (cleaned.startsWith('03') && cleaned.length == 11) {
      return '+92${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('3') && cleaned.length == 10) {
      return '+92$cleaned';
    }
    if (cleaned.startsWith('0092') && cleaned.length == 14) {
      return '+${cleaned.substring(2)}';
    }
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      return '+92${cleaned.substring(1)}';
    }
    if (!cleaned.startsWith('+')) {
      return '+92$cleaned';
    }
    return cleaned;
  }

  static String? validate(String input) {
    final formatted = format(input);
    final cleaned = formatted.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!cleaned.startsWith('+92')) return 'Must start with +92 (Pakistan)';
    final digits = cleaned.substring(3);
    if (digits.length != 10) return 'Must be 10 digits after +92';
    if (!digits.startsWith('3')) return 'Must start with 3 after +92 (e.g. +92 3XX XXX XXXX)';
    if (RegExp(r'^\d+$').hasMatch(digits)) return null;
    return 'Invalid phone number';
  }

  static String display(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+92') && cleaned.length == 13) {
      return '+92 ${cleaned.substring(3, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
    }
    return phone;
  }
}
