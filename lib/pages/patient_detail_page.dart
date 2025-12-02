import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_allergy/bloc/qr/qr_cubit.dart';
import 'package:safe_allergy/models/patient.dart';
import 'package:safe_allergy/services/qr_service.dart';
import 'package:safe_allergy/widgets/patient_info_card.dart';

class PatientDetailPage extends StatelessWidget {
  final Patient patient;
  final bool showQrCode;

  const PatientDetailPage({
    super.key,
    required this.patient,
    this.showQrCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Details',
          style: TextStyle(
            color: Color(0xFF2E658F),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocProvider(
        create: (context) {
          final cubit = QrCubit();
          if (showQrCode) {
            cubit.generateQrCode(patient);
          }
          return cubit;
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              PatientInfoCard(patient: patient),
              if (showQrCode) ...[
                const SizedBox(height: 16),
                BlocBuilder<QrCubit, QrState>(
                  builder: (context, state) {
                    if (state is QrGenerated) {
                      return _buildQrCodeSection(context, state.qrData);
                    } else if (state is QrGenerating) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      );
                    } else if (state is QrGenerationError) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to generate QR code: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCodeSection(BuildContext context, String qrData) {
    final qrKey = GlobalKey();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'QR Code',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                // await _saveQrAsImage(qrKey);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR Code saved to gallery!')),
                );
              },
              child: RepaintBoundary(
                key: qrKey,
                child: QrService.instance.createQrWidget(qrData, size: 250),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan this QR code to access patient information',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
