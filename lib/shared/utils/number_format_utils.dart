import 'package:intl/intl.dart';

String formatTokenCount(int count) {
  if (count > 100000) {
    return '${(count / 1000000).toStringAsFixed(2)}m';
  } else {
    // 0 to 100,000 use k
    return '${(count / 1000).toStringAsFixed(1)}k';
  }
}

String formatFullTokenCount(int count) {
  return NumberFormat('#,###').format(count);
}
