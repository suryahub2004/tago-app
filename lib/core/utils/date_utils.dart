import 'package:intl/intl.dart';

class SvDateUtils {
  const SvDateUtils._();

  static String relative(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    if (difference.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dateTime);
  }
}
