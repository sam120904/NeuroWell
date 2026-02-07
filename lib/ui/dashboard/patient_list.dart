import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../data/models/patient_model.dart';
import '../../data/services/firestore_service.dart';
import 'widgets/add_patient_dialog.dart';
import 'widgets/patient_details_panel.dart';

class PatientList extends StatefulWidget {
  const PatientList({super.key});

  @override
  State<PatientList> createState() => _PatientListState();
}

class _PatientListState extends State<PatientList> {
  Patient? _selectedPatient;

  // Track key to refresh panel when selecting different patient
  Key _panelKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Patient List
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Patients',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const AddPatientDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Patient'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Table Container
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
                        stream: FirestoreService().getPatientsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final patients = snapshot.data!.docs.map((doc) {
                            return Patient.fromMap(
                                doc.id, doc.data() as Map<String, dynamic>);
                          }).toList();

                          if (patients.isEmpty) {
                            return const Center(
                              child: Text(
                                  'No patients found. Add one to get started.'),
                            );
                          }

                          return SingleChildScrollView(
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowColor:
                                  MaterialStateProperty.all(Colors.grey[50]),
                              columns: const [
                                DataColumn(
                                    label: Text('Name',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('ID',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Condition',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Status',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                              rows: patients.map((patient) {
                                final isSelected =
                                    _selectedPatient?.id == patient.id;
                                return DataRow(
                                    selected: isSelected,
                                    onSelectChanged: (selected) {
                                      if (selected == true) {
                                        setState(() {
                                          _selectedPatient = patient;
                                          _panelKey = ValueKey(patient.id);
                                        });
                                      }
                                    },
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: AppColors.primary
                                                  .withOpacity(0.1),
                                              child: Text(
                                                patient.name.isNotEmpty
                                                    ? patient.name[0]
                                                    : '?',
                                                style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(patient.name,
                                                style: TextStyle(
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : Colors.black87,
                                                )),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '#${patient.id.length > 4 ? patient.id.substring(0, 4) : patient.id}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                      DataCell(
                                        Text(patient.condition,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500)),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.green[100]!),
                                          ),
                                          child: Text(
                                            patient.status,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green),
                                          ),
                                        ),
                                      ),
                                    ]);
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Right Side: Patient Details Panel
          // Using Flexible/Expanded to fill remaining space
          Expanded(
            flex: 1,
            child: _selectedPatient != null
                ? PatientDetailsPanel(
                    key: _panelKey,
                    patient: _selectedPatient!,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Select a patient to view details',
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
