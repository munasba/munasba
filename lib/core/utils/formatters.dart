import 'package:intl/intl.dart';

String formatDate(DateTime? date) {
  if (date == null) return 'بدون تاريخ';
  return DateFormat('EEEE d MMMM yyyy', 'ar').format(date);
}

String formatShortDate(DateTime? date) {
  if (date == null) return '—';
  return DateFormat('yyyy-MM-dd').format(date);
}

/// "N يوم متبقي" style countdown label used on the home screen's upcoming list.
String daysRemainingLabel(DateTime? date) {
  if (date == null) return '';
  final days = date.difference(DateTime.now()).inDays;
  if (days < 0) return 'انتهت';
  if (days == 0) return 'اليوم';
  return '$days يوماً متبقي';
}
