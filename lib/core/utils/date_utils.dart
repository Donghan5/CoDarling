import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String toIsoDate(DateTime date) => _isoDate.format(date);

  static String todayIso() => toIsoDate(DateTime.now());

  static DateTime parseIsoDate(String iso) => _isoDate.parse(iso);
}
