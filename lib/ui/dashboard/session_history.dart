import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../data/models/session_model.dart';
import 'package:intl/intl.dart';

import 'dart:html' as html;

class SessionHistory extends StatefulWidget {
  const SessionHistory({super.key});

  @override
  State<SessionHistory> createState() => _SessionHistoryState();
}

class _SessionHistoryState extends State<SessionHistory> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;
  String? _selectedStatus; // 'All', 'Active', 'Completed'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportData(List<Session> sessions) {
    StringBuffer csv = StringBuffer();
    csv.writeln('Session ID,Patient ID,Date,Start Time,Duration (mins),Status,Peak HR');
    
    for (var s in sessions) {
      csv.writeln('${s.id},${s.patientId},${DateFormat('yyyy-MM-dd').format(s.startTime)},${DateFormat('HH:mm').format(s.startTime)},${s.duration.inMinutes},${s.status},${s.peakHeartRate}');
    }

    final blob = html.Blob([csv.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "session_history_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Status'),
        children: [
          SimpleDialogOption(
            onPressed: () { setState(() => _selectedStatus = null); Navigator.pop(context); },
            child: const Text('All'),
          ),
          SimpleDialogOption(
            onPressed: () { setState(() => _selectedStatus = 'Active'); Navigator.pop(context); },
            child: const Text('Active'),
          ),
          SimpleDialogOption(
            onPressed: () { setState(() => _selectedStatus = 'Completed'); Navigator.pop(context); },
            child: const Text('Completed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [

          
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
                child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('sessions').orderBy('startTime', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      var sessions = snapshot.data!.docs.map((doc) {
                        return Session.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                      }).toList();

                      // Apply Filters
                      // 1. Search
                      if (_searchController.text.isNotEmpty) {
                        final query = _searchController.text.toLowerCase();
                        sessions = sessions.where((s) => s.patientId.toLowerCase().contains(query)).toList();
                      }

                      // 2. Date Range
                      if (_dateRange != null) {
                        sessions = sessions.where((s) => 
                          s.startTime.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) && 
                          s.startTime.isBefore(_dateRange!.end.add(const Duration(days: 1)))
                        ).toList();
                      }

                      // 3. Status
                      if (_selectedStatus != null) {
                        sessions = sessions.where((s) => s.status == _selectedStatus).toList();
                      }

                      // Update the Export button logic?
                      // The Export button is in the top bar, which is outside this builder scope in the previous design.
                      // To fix this, I will move the "Export" button to be rendered HERE or lift the state.
                      // The cleanest way in a single file edit without massive indentation changes:
                      // Use a ValueListenable or just put the Export button inside the builder?
                      // Let's actually wrap the whole return of the build method in the StreamBuilder so the top bar also has access.
                      // That is a larger change.
                      // Alternative: Pass the data to the parent? No.
                      
                      // Let's stick effectively to the previous structure but I will handle the Export button click
                      // by finding a way... actually, the easiest way is to wrap the whole UI in StreamBuilder.
                      // I will return the StreamBuilder at the top level of `build`.
                      return Column(
                        children: [
                           // Moved Filter Bar Inside
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
                                     controller: _searchController,
                                     decoration: const InputDecoration(
                                       hintText: 'Search sessions by Patient ID...',
                                       prefixIcon: Icon(Icons.search),
                                       border: InputBorder.none,
                                     ),
                                     onChanged: (val) => setState(() {}),
                                   ),
                                 ),
                                 const VerticalDivider(),
                                 TextButton.icon(
                                   onPressed: () => _selectDateRange(context),
                                   icon: const Icon(Icons.calendar_month),
                                   label: Text(_dateRange == null 
                                     ? 'Last 30 Days' 
                                     : '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}'),
                                 ),
                                 TextButton.icon(
                                   onPressed: () => _showFilterDialog(context),
                                   icon: Icon(Icons.filter_list, color: _selectedStatus != null ? AppColors.primary : null),
                                   label: Text(_selectedStatus ?? 'Filters'),
                                 ),
                                 TextButton.icon(
                                   onPressed: () => _exportData(sessions),
                                   icon: const Icon(Icons.download),
                                   label: const Text('Export'),
                                 ),
                               ],
                             ),
                           ),
                           const SizedBox(height: 24),
                           Expanded(
                             child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 300),
                                child: sessions.isEmpty 
                                  ? const Center(child: Text('No sessions match your filters.'))
                                  : DataTable(
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
                        ],
                      );
                    },
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
