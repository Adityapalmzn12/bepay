import 'package:flutter_test/flutter_test.dart';

import 'package:bepay/core/utils/date_formatter.dart';

void main() {
  test('formats a UTC timestamp in local time', () {
    final createdAt = DateTime.utc(2026, 10, 22, 18, 30);
    final local = createdAt.toLocal();
    final formatted = formatTransactionDate(createdAt);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';

    expect(
      formatted,
      '${local.day} ${months[local.month - 1]} ${local.year}, '
      '$hour12:$minute $period',
    );
    expect(formatted.contains('2026'), isTrue);
  });
}
