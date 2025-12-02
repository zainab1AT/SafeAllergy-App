import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_allergy/bloc/nfc/nfc_cubit.dart';
import 'package:safe_allergy/pages/patient_detail_page.dart';
import 'package:safe_allergy/widgets/error_dialog.dart';
import 'package:safe_allergy/widgets/loading_indicator.dart';

class NfcReadPage extends StatefulWidget {
  const NfcReadPage({super.key});

  @override
  State<NfcReadPage> createState() => _NfcReadPageState();
}

class _NfcReadPageState extends State<NfcReadPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NfcCubit>().checkAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Read NFC Tag',
          style: TextStyle(
            color: Color(0xFF2E658F),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<NfcCubit, NfcState>(
        listener: (context, state) {
          if (state is NfcReadSuccess) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientDetailPage(patient: state.patient),
              ),
            );
          } else if (state is NfcReadError) {
            ErrorDialog.show(context, 'Read Failed', state.message);
          } else if (state is NfcNotAvailable) {
            ErrorDialog.show(context, 'NFC Not Available', state.message);
          }
        },
        builder: (context, state) {
          if (state is NfcChecking) {
            return const LoadingIndicator(
              message: 'Checking NFC availability...',
            );
          }

          if (state is NfcNotAvailable) {
            return _buildNotAvailableView(context);
          }

          if (state is NfcReading) {
            return _buildReadingView(context);
          }

          if (state is NfcAvailable || state is NfcInitial) {
            return _buildReadyView(context);
          }

          return _buildReadyView(context);
        },
      ),
    );
  }

  Widget _buildReadyView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nfc, size: 100, color: Colors.blue),
          const SizedBox(height: 24),
          Text(
            'Ready to Read',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Hold your device near the NFC tag to read patient data',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<NfcCubit>().readPatientData();
              },
              icon: const Icon(Icons.nfc),
              label: const Text('Start Reading'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Reading NFC Tag...',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Keep your device close to the NFC tag',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () {
              context.read<NfcCubit>().stopSession();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAvailableView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nfc_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 24),
          Text(
            'NFC Not Available',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'This device does not support NFC or NFC is not enabled.\n\nPlease use QR code scanning instead.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
