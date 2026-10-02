DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Stable document id for a day: `2026-10-02`.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

typedef YearMonth = ({int year, int month});

YearMonth monthOf(DateTime d) => (year: d.year, month: d.month);

YearMonth addMonths(YearMonth m, int delta) {
  final d = DateTime(m.year, m.month + delta);
  return (year: d.year, month: d.month);
}
