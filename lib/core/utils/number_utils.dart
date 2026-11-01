import 'package:intl/intl.dart';

class SvNumberUtils {
  const SvNumberUtils._();

  static String compact(num value) => NumberFormat.compact().format(value);
}
