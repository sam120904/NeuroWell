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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
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
                           // Responsive Filter Bar
                           Container(
                             padding: EdgeInsets.all(isMobile ? 12 : 16),
                             decoration: BoxDecoration(
                               color: Theme.of(context).cardColor,
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: Colors.grey.withOpacity(0.2)),
                             ),
                             child: isMobile
                                 ? Column(
                                     crossAxisAlignment: CrossAxisAlignment.stretch,
                                     children: [
                                       // Search field on top
                                       TextField(
                                         controller: _searchController,
                                         decoration: const InputDecoration(
                                           hintText: 'Search by Patient ID...',
                                           prefixIcon: Icon(Icons.search),
                                           border: InputBorder.none,
                                           isDense: true,
                                         ),
                                         onChanged: (val) => setState(() {}),
                                       ),
                                       const SizedBox(height: 8),
                                       // Filter buttons wrap
                                       Wrap(
                                         spacing: 8,
                                         runSpacing: 8,
                                         children: [
                                           TextButton.icon(
                                             onPressed: () => _selectDateRange(context),
                                             icon: const Icon(Icons.calendar_month, size: 18),
                                             label: Text(
                                               _dateRange == null 
                                                 ? 'Date' 
                                                 : '${DateFormat('MM/dd').format(_dateRange!.start)}-${DateFormat('MM/dd').format(_dateRange!.end)}',
                                               style: const TextStyle(fontSize: 12),
                                             ),
                                           ),
                                           TextButton.icon(
                                             onPressed: () => _showFilterDialog(context),
                                             icon: Icon(Icons.filter_list, size: 18, color: _selectedStatus != null ? AppColors.primary : null),
                                             label: Text(_selectedStatus ?? 'Filter', style: const TextStyle(fontSize: 12)),
                                           ),
                                           TextButton.icon(
                                             onPressed: () => _exportData(sessions),
                                             icon: const Icon(Icons.download, size: 18),
                                             label: const Text('Export', style: TextStyle(fontSize: 12)),
                                           ),
                                         ],
                                       ),
                                     ],
                                   )
                                 : Row(
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
                                        DataColumn(label: Text('Patient', style: TextStyle(fontWeight: FontWeight.bold))),
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
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(session.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                Container(
                                                  margin: const EdgeInsets.only(top: 2),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text('#${session.patientId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                ),
                                              ],
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
                                              onPressed: () => _showSessionDetails(context, session),
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

  void _showSessionDetails(BuildContext context, Session session) async {
    // Fetch full session data from Firestore
    final doc = await FirebaseFirestore.instance.collection('sessions').doc(session.id).get();
    final data = doc.data();
    
    if (!mounted || data == null) return;
    
    showDialog(
      context: context,
      builder: (context) => _SessionDetailsDialog(
        session: session,
        transcript: data['transcript'] as String? ?? 'No transcript available.',
        aiReport: data['aiReport'] as String? ?? 'No AI report generated.',
        // Handle both String and int types from Firestore
        avgHeartRate: _parseToInt(data['avgHeartRate']),
        avgSpo2: _parseToInt(data['avgSpo2']),
      ),
    );
  }

  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}

/// Dialog to display saved session details
class _SessionDetailsDialog extends StatelessWidget {
  final Session session;
  final String transcript;
  final String aiReport;
  final int avgHeartRate;
  final int avgSpo2;

  const _SessionDetailsDialog({
    required this.session,
    required this.transcript,
    required this.aiReport,
    required this.avgHeartRate,
    required this.avgSpo2,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: screenSize.width * 0.8,
        height: screenSize.height * 0.85,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Session Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(
                          '${DateFormat('MMM dd, yyyy').format(session.startTime)} at ${DateFormat('hh:mm a').format(session.startTime)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('Duration', '${session.duration.inMinutes} mins', Icons.timer, Colors.purple),
                  _miniStat('Avg HR', '$avgHeartRate BPM', Icons.favorite, Colors.red),
                  _miniStat('Peak HR', '${session.peakHeartRate} BPM', Icons.trending_up, Colors.orange),
                  _miniStat('Avg SpO2', '$avgSpo2%', Icons.water_drop, Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Tabs: Transcript | AI Report
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'AI Report'),
                        Tab(text: 'Transcript'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // AI Report Tab
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blue[50]?.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                aiReport,
                                style: const TextStyle(fontSize: 14, height: 1.7, color: Colors.black87),
                              ),
                            ),
                          ),
                          // Transcript Tab
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                transcript,
                                style: TextStyle(fontSize: 14, height: 1.7, color: Colors.grey[700]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Close Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
