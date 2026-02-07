import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/models/session_model.dart';
import 'package:intl/intl.dart';

class SessionHistory extends StatelessWidget {
  const SessionHistory({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final sessions = [
      Session(id: '1', patientId: 'NW-8842', startTime: DateTime(2023, 10, 24, 10, 30), duration: const Duration(minutes: 45), status: 'Completed', peakHeartRate: 115),
      Session(id: '2', patientId: 'NW-9102', startTime: DateTime(2023, 10, 24, 9, 15), duration: const Duration(minutes: 30), status: 'Active', peakHeartRate: 88),
      Session(id: '3', patientId: 'NW-7721', startTime: DateTime(2023, 10, 23, 16, 45), duration: const Duration(minutes: 60), status: 'Completed', peakHeartRate: 102),
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Filter Bar
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: Theme.of(context).cardColor,
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.grey.withOpacity(0.2)),
             ),
             child: Row(
               children: [
                 Expanded(
                   child: TextField(
                     decoration: InputDecoration(
                       hintText: 'Search sessions...',
                       prefixIcon: const Icon(Icons.search),
                       border: InputBorder.none,
                     ),
                   ),
                 ),
                 const VerticalDivider(),
                 TextButton.icon(
                   onPressed: (){},
                   icon: const Icon(Icons.calendar_month),
                   label: const Text('Last 30 Days'),
                 ),
                 TextButton.icon(
                   onPressed: (){},
                   icon: const Icon(Icons.filter_list),
                   label: const Text('Filters'),
                 ),
                 TextButton.icon(
                   onPressed: (){},
                   icon: const Icon(Icons.download),
                   label: const Text('Export'),
                 ),
               ],
             ),
          ),
          const SizedBox(height: 24),
          
          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 300), // Approximate width adjustment
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                      columns: const [
                        DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Patient ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Peak HR', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      ],
                      rows: sessions.map((session) {
                        return DataRow(cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(DateFormat('MMM dd, yyyy').format(session.startTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(DateFormat('hh:mm a').format(session.startTime), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('#${session.patientId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          DataCell(
                            Row(children: [
                              const Icon(Icons.schedule, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${session.duration.inMinutes} mins'),
                            ]),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: session.status == 'Active' ? Colors.blue[50] : Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: session.status == 'Active' ? Colors.blue[100]! : Colors.green[100]!,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (session.status == 'Active')
                                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), margin: const EdgeInsets.only(right: 6)),
                                  Text(
                                    session.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: session.status == 'Active' ? AppColors.primary : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Row(children: [
                              const Icon(Icons.favorite, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text('${session.peakHeartRate} BPM', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ]),
                          ),
                          DataCell(
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                session.status == 'Active' ? 'Join Session' : 'View Details',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
