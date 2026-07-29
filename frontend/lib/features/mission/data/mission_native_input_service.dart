import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

enum MissionPhotoSource {
  camera,
  gallery,
}

class MissionPhotoInput {
  const MissionPhotoInput({
    required this.uploadKey,
    required this.previewLabel,
  });

  final String uploadKey;
  final String previewLabel;
}

class MissionInputException implements Exception {
  const MissionInputException(this.message);

  final String message;
}

class MissionNativeInputService {
  MissionNativeInputService({
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<MissionPhotoInput?> pickPhoto({
    required String missionId,
    required MissionPhotoSource source,
  }) async {
    if (source == MissionPhotoSource.camera) {
      await _ensureCameraPermission();
    }

    try {
      final image = await _imagePicker.pickImage(
        source: source == MissionPhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 82,
      );
      if (image == null) {
        return null;
      }
      final sourceName =
          source == MissionPhotoSource.camera ? 'camera' : 'gallery';
      final previewLabel =
          source == MissionPhotoSource.camera ? '카메라 촬영 이미지' : '갤러리 선택 이미지';
      return MissionPhotoInput(
        uploadKey: 'local:$missionId:$sourceName:${image.name}',
        previewLabel: previewLabel,
      );
    } catch (_) {
      throw const MissionInputException('이미지를 불러오지 못했습니다. 다시 시도해주세요.');
    }
  }

  Future<String?> scanQrCode(BuildContext context) async {
    await _ensureCameraPermission();
    if (!context.mounted) {
      return null;
    }
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const MissionQrScannerScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) {
      return;
    }
    if (status.isPermanentlyDenied) {
      throw const MissionInputException(
          '카메라 권한이 차단되어 있습니다. 앱 설정에서 권한을 허용해주세요.');
    }
    throw const MissionInputException('카메라 권한이 필요합니다.');
  }
}

class MissionQrScannerScreen extends StatefulWidget {
  const MissionQrScannerScreen({super.key});

  @override
  State<MissionQrScannerScreen> createState() => _MissionQrScannerScreenState();
}

class _MissionQrScannerScreenState extends State<MissionQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (code == null || code.isBlank) {
      return;
    }
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR 스캔'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF56C787), width: 4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              '미션 안내판의 QR 코드를 프레임 안에 맞춰주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  bool get isBlank => trim().isEmpty;
}
