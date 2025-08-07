import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/models/table_model.dart';

class TableCardWidget extends StatelessWidget {
  final TableModel table;
  final List<Map<String, dynamic>> assignedGuests;
  final int confirmedGuestCount;
  final void Function()? onEdit;
  final void Function()? onDelete;
  final void Function()? onAssignGuest;
  final void Function(String guestId)? onRemoveGuest;

  const TableCardWidget({
    Key? key,
    required this.table,
    required this.assignedGuests,
    required this.confirmedGuestCount,
    this.onEdit,
    this.onDelete,
    this.onAssignGuest,
    this.onRemoveGuest,
  }) : super(key: key);

  String getTableTypeIcon(String tableType) {
    if (tableType.isEmpty) return AppConstants.tableIconSquare;
    switch (tableType.toLowerCase()) {
      case 'rund':
        return AppConstants.tableIconCircle;
      case 'oval':
        return AppConstants.tableIconOval;
      case 'recheckig':
        return AppConstants.tableIconRectangle;
      case 'quadratisch':
        return AppConstants.tableIconSquare;
      default:
        return AppConstants.tableIconSquare;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade300,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  table.nameOrNumber.isNotEmpty
                                      ? table.nameOrNumber[0].toUpperCase() +
                                          table.nameOrNumber.substring(1)
                                      : '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  AppConstants.tableTypePrefix,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Image.asset(
                                  getTableTypeIcon(table.tableType),
                                  width: 20,
                                  height: 20,
                                  color: Color.fromARGB(255, 107, 69, 106),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppConstants.maxGuestsDisplay}${table.maxGuests}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        FontAwesomeIcons.penToSquare,
                        size: 18,
                      ),
                      onPressed: onEdit,
                      color: Color.fromARGB(255, 107, 69, 106),
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.trashCan,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppConstants.assignedGuestsCount}$confirmedGuestCount/${table.maxGuests})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...assignedGuests.map((guest) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      guest['name'].isNotEmpty
                                          ? guest['name'][0].toUpperCase() +
                                              guest['name'].substring(1)
                                          : '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      guest['takePart']
                                          ? 'Bestätigt'
                                          : guest['mayBeTakePart']
                                              ? 'Vielleicht'
                                              : 'Abgelehnt',
                                      style: TextStyle(
                                        color: guest['takePart']
                                            ? Colors.green[700]
                                            : guest['mayBeTakePart']
                                                ? Colors.amber[700]
                                                : Colors.red[400],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: onRemoveGuest != null
                                  ? () => onRemoveGuest!(guest['id'])
                                  : null,
                              color: Colors.red[400],
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      )),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(
                      AppConstants.assignGuestButton,
                      style:
                          TextStyle(color: Color.fromARGB(255, 107, 69, 106)),
                    ),
                    onPressed: onAssignGuest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
