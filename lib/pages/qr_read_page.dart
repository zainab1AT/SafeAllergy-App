import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:safe_allergy/bloc/qr/qr_cubit.dart';
import 'package:safe_allergy/pages/patient_detail_page.dart';
import 'package:safe_allergy/widgets/error_dialog.dart';
import 'package:safe_allergy/widgets/loading_indicator.dart';

class QrReadPage extends StatefulWidget {
  const QrReadPage({super.key});

  @override
  State<QrReadPage> createState() => _QrReadPageState();
}

class _QrReadPageState extends State<QrReadPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _torchEnabled = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
    _controller.toggleTorch();
  }

  void _switchCamera() {
    setState(() {
      _cameraFacing = _cameraFacing == CameraFacing.back
          ? CameraFacing.front
          : CameraFacing.back;
    });
    _controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QrCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Scan QR Code',
            style: TextStyle(
              color: Color(0xFF2E658F),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _torchEnabled ? Icons.flash_on : Icons.flash_off,
                color: _torchEnabled ? Colors.yellow : Colors.grey,
              ),
              onPressed: _toggleTorch,
            ),
            IconButton(
              icon: Icon(
                _cameraFacing == CameraFacing.back
                    ? Icons.camera_rear
                    : Icons.camera_front,
                color: Color(0xFF2E658F),
              ),
              onPressed: _switchCamera,
            ),
          ],
        ),
        body: BlocConsumer<QrCubit, QrState>(
          listener: (context, state) {
            if (state is QrScanSuccess) {
              _controller.stop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientDetailPage(patient: state.patient),
                ),
              );
            } else if (state is QrScanError) {
              _controller.stop();
              ErrorDialog.show(context, 'Scan Failed', state.message);
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  context.read<QrCubit>().reset();
                  _controller.start();
                }
              });
            }
          },
          builder: (context, state) {
            if (state is QrScanning) {
              return Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          context.read<QrCubit>().parseQrData(
                            barcode.rawValue!,
                          );
                          break;
                        }
                      }
                    },
                  ),
                  const Center(
                    child: LoadingIndicator(message: 'Scanning QR code...'),
                  ),
                ],
              );
            }

            return Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        context.read<QrCubit>().parseQrData(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Position QR code within the frame',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
