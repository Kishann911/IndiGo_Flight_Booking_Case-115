/// Pure-Dart display formatting (no intl dependency).
class Fmt {
  Fmt._();

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Rupees with Indian digit grouping: 12450 → "₹12,450", 1234567 → "₹12,34,567".
  static String inr(int amount) => '${amount < 0 ? '-' : ''}₹${groupIndian(amount.abs())}';

  /// 1234567 → "12,34,567".
  static String groupIndian(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  /// "2h 5m", "55m", "3h".
  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');

  /// 24-hour "06:05".
  static String time(DateTime t) => '${_pad2(t.hour)}:${_pad2(t.minute)}';

  /// "Tue, 30 Sep 2026".
  static String date(DateTime d) => '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

  /// "30 Sep".
  static String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  /// "Tue 30 Sep".
  static String weekdayDayMonth(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  /// "September 2026".
  static String monthYear(DateTime d) => '${monthName(d.month)} ${d.year}';

  static String monthName(int month) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][month - 1];

  /// "Mon".."Sun" for weekday 1..7.
  static String weekdayShort(int weekday) => _weekdays[weekday - 1];
}
