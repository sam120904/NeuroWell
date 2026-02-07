import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import 'widgets/add_patient_dialog.dart';
import '../monitoring/live_view.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  String? _selectedPatientId;
  String _deviceStatus = 'Disconnected'; // 'Disconnected', 'Connecting', 'Connected'
  final TextEditingController _notesController = TextEditingController();
  bool _isConnecting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addPatient() {
    showDialog(
      context: context,
      builder: (context) => const AddPatientDialog(),
    );
  }

  void _toggleDeviceConnection() async {
    if(_deviceStatus == 'Connected') {
      setState(() => _deviceStatus = 'Disconnected');
      return;
    }

    setState(() {
      _isConnecting = true;
      _deviceStatus = 'Connecting';
    });

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isConnecting = false;
        _deviceStatus = 'Connected';
      });
    }
  }

  void _startSession() {
    if (_selectedPatientId != null && _deviceStatus == 'Connected') {
       // Navigate to Live View. 
       Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LiveMonitoringView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if "Start" is enabled
    final isReady = _selectedPatientId != null && _deviceStatus == 'Connected';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView( 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Session Setup',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Configure patient details and device connection before beginning therapy.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Patient & Notes
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // 1. Patient Selection
                      _buildCard(
                        context,
                        title: '1. Patient Selection',
                        child: Row(
                          children: [
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('patients').orderBy('name').snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const LinearProgressIndicator();
                                  }
                                  
                                  List<DropdownMenuItem<String>> patientItems = snapshot.data!.docs.map((doc) {
                                    return DropdownMenuItem<String>(
                                      value: doc.id,
                                      child: Text(doc['name'] ?? 'Unknown'),
                                    );
                                  }).toList();

                                  return DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      hintText: 'Select a patient...',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    ),
                                    items: patientItems,
                                    value: _selectedPatientId,
                                    onChanged: (val) => setState(() => _selectedPatientId = val),
                                    dropdownColor: Colors.white,
                                  );
                                }
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _addPatient,
                              icon: const Icon(Icons.person_add_outlined, size: 18),
                              label: const Text('Add New'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                backgroundColor: Colors.grey[100],
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Pre-session Notes
                      _buildCard(
                        context, 
                        title: '3. Pre-session Notes & Goals', 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SESSION OBJECTIVES', 
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _notesController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Enter specific therapy goals, baseline observations, or patient-reported status...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.grey[50], 
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[200]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                            ),
                          ],
                        )
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column: Device Status & Start
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // 2. Device Status
                      _buildCard(
                        context,
                        title: '2. Device Status',
                        action: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.grey),
                          onPressed: _deviceStatus == 'Connecting' ? null : _toggleDeviceConnection,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DEVICE ID',
                                        style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'ESP32_NEUROWELL_01',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _deviceStatus == 'Connected' 
                                          ? Colors.green.withOpacity(0.1) 
                                          : (_deviceStatus == 'Connecting' ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _deviceStatus == 'Connected' 
                                          ? Colors.green.withOpacity(0.3) 
                                          : (_deviceStatus == 'Connecting' ? Colors.orange.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        if (_deviceStatus == 'Connecting')
                                          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                                        else 
                                          Icon(
                                            _deviceStatus == 'Connected' ? Icons.check_circle : Icons.error_outline,
                                            size: 14,
                                            color: _deviceStatus == 'Connected' 
                                              ? Colors.green 
                                              : (_deviceStatus == 'Connecting' ? Colors.orange : Colors.red),
                                          ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _deviceStatus.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10, 
                                            fontWeight: FontWeight.bold,
                                            color: _deviceStatus == 'Connected' 
                                              ? Colors.green 
                                              : (_deviceStatus == 'Connecting' ? Colors.orange : Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _deviceStatus == 'Connecting' ? null : _toggleDeviceConnection,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  foregroundColor: AppColors.primary,
                                ),
                                child: Text(_deviceStatus == 'Connected' ? 'Disconnect Device' : 'Check Connection'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(
                              'Ensure patient is seated comfortably. Device readings will stabilize automatically once the session begins.',
                              style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontSize: 13, height: 1.5),
                            )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Start Session
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isReady ? _startSession : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Start Neurowell Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required Widget child, Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: AppColors.primary.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                       title.split('. ')[0], // "1", "2"
                       style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Text(
                     title.split('. ')[1], 
                     style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
                   ),
                 ],
               ),
               if (action != null) action,
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
