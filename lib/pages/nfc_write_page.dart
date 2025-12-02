import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:safe_allergy/bloc/nfc/nfc_cubit.dart';
import 'package:safe_allergy/bloc/patient/patient_cubit.dart';
import 'package:safe_allergy/bloc/qr/qr_cubit.dart';
import 'package:safe_allergy/models/patient.dart';
import 'package:safe_allergy/pages/patient_detail_page.dart';
import 'package:safe_allergy/utils/constants.dart';
import 'package:safe_allergy/utils/validators.dart';
import 'package:safe_allergy/widgets/error_dialog.dart';
import 'package:safe_allergy/widgets/loading_indicator.dart';

class NfcWritePage extends StatefulWidget {
  const NfcWritePage({super.key});

  @override
  State<NfcWritePage> createState() => _NfcWritePageState();
}

class _NfcWritePageState extends State<NfcWritePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _medicalFileNumberController = TextEditingController();
  final _departmentController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyNumberController = TextEditingController(
    text: AppConstants.defaultEmergencyNumber,
  );
  final _hospitalNameController = TextEditingController();

  List<String> _selectedAllergies = [];

  @override
  void dispose() {
    _fullNameController.dispose();
    _medicalFileNumberController.dispose();
    _departmentController.dispose();
    _emergencyContactController.dispose();
    _emergencyNumberController.dispose();
    _hospitalNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NfcCubit()..checkAvailability()),
        BlocProvider(create: (_) => PatientCubit()),
        BlocProvider(create: (_) => QrCubit()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Enter Patient Information',
            style: TextStyle(
              color: Color(0xFF2E658F),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<NfcCubit, NfcState>(
          listener: (context, state) {
            if (state is NfcWriteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Patient data written successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              _showSuccessDialog(context);
            } else if (state is NfcWriteError) {
              ErrorDialog.show(context, 'Write Failed', state.message);
            } else if (state is NfcNotAvailable) {
              ErrorDialog.show(context, 'NFC Not Available', state.message);
            }
          },
          builder: (context, state) {
            if (state is NfcWriting) {
              return const LoadingIndicator(message: 'Writing to NFC tag...');
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _medicalFileNumberController,
                      label: 'Medical File Number',
                      icon: Icons.badge,
                      validator: Validators.validateMedicalFileNumber,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _departmentController,
                      label: 'Department',
                      icon: Icons.business,
                      validator: Validators.validateDepartment,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _hospitalNameController,
                      label: 'Hospital Name',
                      icon: Icons.local_hospital,
                      validator: Validators.validateHospitalName,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emergencyContactController,
                      label: 'Emergency Contact',
                      icon: Icons.contact_emergency,
                      validator: Validators.validateEmergencyContact,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emergencyNumberController,
                      label: 'Emergency Number',
                      icon: Icons.phone,
                      validator: Validators.validateEmergencyNumber,
                    ),
                    const SizedBox(height: 16),
                    _buildAllergiesField(context),
                    const SizedBox(height: 32),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [Image.asset('assets/images/info.png', height: 180)],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  Widget _buildAllergiesField(BuildContext context) {
    return MultiSelectDialogField<String>(
      items: AppConstants.predefinedAllergies
          .map((allergy) => MultiSelectItem<String>(allergy, allergy))
          .toList(),
      title: const Text('Select Allergies'),
      selectedColor: Colors.blue,
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: Colors.grey)),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      buttonIcon: const Icon(Icons.arrow_drop_down),
      buttonText: Text(
        _selectedAllergies.isEmpty
            ? 'Select Allergies'
            : '${_selectedAllergies.length} selected',
        style: const TextStyle(color: Colors.black87),
      ),
      onConfirm: (values) {
        setState(() {
          _selectedAllergies = values;
        });
      },
      chipDisplay: MultiSelectChipDisplay(
        onTap: (item) {
          setState(() {
            _selectedAllergies.remove(item);
          });
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    const Color mainColor = Color(0xFF2E658F);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleWrite(context),
            icon: const Icon(Icons.nfc, color: Colors.white),
            label: const Text(
              'Write to NFC Tag',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _handlePreview(context),
            icon: Icon(Icons.preview, color: mainColor),
            label: Text(
              'Preview & Generate QR',
              style: TextStyle(color: mainColor, fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: mainColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleWrite(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final validationError = Validators.validateAllergies(_selectedAllergies);
    if (validationError != null) {
      ErrorDialog.show(context, 'Validation Error', validationError);
      return;
    }

    final patient = Patient(
      fullName: _fullNameController.text.trim(),
      medicalFileNumber: _medicalFileNumberController.text.trim(),
      department: _departmentController.text.trim(),
      allergies: _selectedAllergies,
      emergencyContact: _emergencyContactController.text.trim(),
      emergencyNumber: _emergencyNumberController.text.trim(),
      hospitalName: _hospitalNameController.text.trim(),
    );

    context.read<NfcCubit>().writePatientData(patient);
  }

  void _handlePreview(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final validationError = Validators.validateAllergies(_selectedAllergies);
    if (validationError != null) {
      ErrorDialog.show(context, 'Validation Error', validationError);
      return;
    }

    final patient = Patient(
      fullName: _fullNameController.text.trim(),
      medicalFileNumber: _medicalFileNumberController.text.trim(),
      department: _departmentController.text.trim(),
      allergies: _selectedAllergies,
      emergencyContact: _emergencyContactController.text.trim(),
      emergencyNumber: _emergencyNumberController.text.trim(),
      hospitalName: _hospitalNameController.text.trim(),
    );

    context.read<QrCubit>().generateQrCode(patient);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailPage(patient: patient, showQrCode: true),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: const Text(
          'Patient data has been written to the NFC tag successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
