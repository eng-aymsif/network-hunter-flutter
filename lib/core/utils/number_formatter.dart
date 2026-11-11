class NumberFormatter {
  /// زيادة الرقم بمقدار 1 مع الحفاظ التام على الأصفار التي باليسار
  static String nextNumber(String numStr) {
    try {
      final clean = numStr.trim();
      if (clean.isEmpty) return numStr;
      final val = BigInt.parse(clean);
      final incremented = val + BigInt.one;
      return incremented.toString().padLeft(clean.length, '0');
    } catch (_) {
      return numStr;
    }
  }
}
