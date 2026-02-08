import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import 'widgets/add_patient_dialog.dart';
import '../monitoring/live_view.dart';
import '../../data/services/blynk_service.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  String? _selectedPatientId;
  final TextEditingController _notesController = TextEditingController();
  final BlynkService _blynkService = BlynkService();

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

  @override
  void initState() {
    super.initState();
    _blynkService.startPolling();
  }

  // Removed _toggleDeviceConnection as it is now automatic via BlynkService

  void _startSession() {
    // Pass the selected patient ID and notes to the live view if needed
    // For now just navigating
    if (_selectedPatientId != null) {
       Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LiveMonitoringView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BlynkStatus>(
      stream: _blynkService.statusStream,
      initialData: _blynkService.currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? BlynkStatus.offline;
        final isDeviceConnected = status != BlynkStatus.offline && status != BlynkStatus.loading;
        
        // Determine if "Start" is enabled
        final isReady = _selectedPatientId != null && isDeviceConnected;
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 1024;
        final isTablet = screenWidth >= 768 && screenWidth < 1024;

        return Padding(
          padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
          child: SingleChildScrollView( 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Session Setup',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Configure patient details and device connection before beginning therapy.',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // Responsive layout: Row on desktop, Column on tablet/mobile
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Patient & Notes
                      Expanded(
                        flex: 3,
                        child: _buildLeftColumn(),
                      ),
                      const SizedBox(width: 24),
                      // Right Column: Device Status & Start
                      Expanded(
                        flex: 2,
                        child: _buildRightColumn(isReady, status),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeftColumn(),
                      const SizedBox(height: 24),
                      _buildRightColumn(isReady, status),
                    ],
                  ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      children: [
        // 1. Patient Selection
        _buildCard(
          context,
          title: '1. Patient Selection',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StreamBuilder<QuerySnapshot>(
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
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addPatient,
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Add New Patient'),
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
                );
              }
              return Row(
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
              );
            },
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
    );
  }

  Widget _buildRightColumn(bool isReady, BlynkStatus status) {
    bool isConnected = status != BlynkStatus.offline && status != BlynkStatus.loading;
    bool isLoading = status == BlynkStatus.loading;
    
    String statusText = 'DISCONNECTED';
    Color statusColor = Colors.red;
    IconData statusIcon = Icons.error_outline;

    if (isLoading) {
      statusText = 'CONNECTING...';
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
    } else if (isConnected) {
      statusText = 'CONNECTED';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }
    
    return Column(
      children: [
        // 2. Device Status
        _buildCard(
          context,
          title: '2. Device Status',
          action: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: null, // Connection is automatic
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
                    Flexible(
                      child: Column(
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
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isLoading)
                            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                          else 
                            Icon(
                              statusIcon,
                              size: 14,
                              color: statusColor,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold,
                              color: statusColor,
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
                  onPressed: null, // Connection is automatic
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    foregroundColor: AppColors.primary,
                    disabledForegroundColor: Colors.grey,
                  ),
                  child: const Text('Connection is Automatic'),
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
