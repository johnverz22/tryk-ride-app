import 'package:intl/intl.dart';

class FormatDateUseCase {
  String cardFormat(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(dateTime); // e.g. "Aug 26, 2023 at 02:30 PM"
  }
}