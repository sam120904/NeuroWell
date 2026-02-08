import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/patient_model.dart';
import '../../../../data/services/firestore_service.dart';
import '../../../../core/constants.dart';

class PatientDetailsPanel extends StatefulWidget {
  final Patient patient;

  const PatientDetailsPanel({super.key, required this.patient});

  @override
  State<PatientDetailsPanel> createState() => _PatientDetailsPanelState();
}

class _PatientDetailsPanelState extends State<PatientDetailsPanel> {
  final _noteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    setState(() => _isAddingNote = true);
    try {
      await FirestoreService().addPatientNote(
        widget.patient.id,
        _noteController.text.trim(),
      );
      _noteController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding note: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAddingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Profile
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  widget.patient.name.isNotEmpty ? widget.patient.name[0] : '?',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: #${widget.patient.id.length > 6 ? widget.patient.id.substring(0, 6) : widget.patient.id}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.patient.status == 'Active'
                      ? Colors.green[50]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.patient.status == 'Active'
                        ? Colors.green[100]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  widget.patient.status,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.patient.status == 'Active'
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Patient Details
          _buildDetailRow(Icons.cake, 'Age', '${widget.patient.age} years'),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.medical_services,
            'Condition',
            widget.patient.condition,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.phone, 'Contact', widget.patient.contactNumber),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today,
            'Added On',
            DateFormat('MMM dd, yyyy').format(widget.patient.dateAdded),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Notes Section
          Text(
            'Key Notes & Observations',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Add Note Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add a clinical note...',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _addNote(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isAddingNote ? null : _addNote,
                icon: _isAddingNote
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notes List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService().getPatientNotesStream(
                widget.patient.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notes = snapshot.data!.docs;
                if (notes.isEmpty) {
                  return Center(
                    child: Text(
                      'No notes yet.',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index].data() as Map<String, dynamic>;
                    final date =
                        (note['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['content'] ?? '',
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('MMM dd, HH:mm').format(date),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
