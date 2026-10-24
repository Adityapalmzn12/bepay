import 'package:bepay/core/constants/app_constants.dart';

String formatTransactionDate(DateTime createdAtUtc) {
  final local = createdAtUtc.toLocal();
  final hour24 = local.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? AppStrings.pm : AppStrings.am;
  return '${local.day} ${AppStrings.months[local.month - 1]} ${local.year}, '
      '$hour12:$minute $period';
}
