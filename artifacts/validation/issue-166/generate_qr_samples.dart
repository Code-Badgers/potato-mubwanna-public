import 'dart:io';

import 'package:qr/qr.dart';

const samples = <({String code, String title, String payload})>[
  (
    code: 'MISSION_PYEONGCHANG_QR',
    title: '평창 체험장 QR 찾기',
    payload: 'gamjamubwatna://mission/qr/MISSION_PYEONGCHANG_QR',
  ),
  (
    code: 'MISSION_SOKCHO_ONNURI_QR',
    title: '속초 시장 QR 찾기',
    payload: 'gamjamubwatna://mission/qr/MISSION_SOKCHO_ONNURI_QR',
  ),
  (
    code: 'MISSION_CHEORWON_GOSEOKJEONG_QR',
    title: '철원 고석정 철새 QR 찾기',
    payload: 'gamjamubwatna://mission/qr/MISSION_CHEORWON_GOSEOKJEONG_QR',
  ),
  (
    code: 'MISSION_HOENGSEONG_HANWOO_QR',
    title: '횡성 한우 떡갈비 요리 챌린지',
    payload: 'gamjamubwatna://mission/qr/MISSION_HOENGSEONG_HANWOO_QR',
  ),
  (
    code: 'MISSION_HWACHEON_SANCHEONEO_QR',
    title: '화천 산천어 미션',
    payload: 'gamjamubwatna://mission/qr/MISSION_HWACHEON_SANCHEONEO_QR',
  ),
];

void main() {
  const outputDir = '../artifacts/validation/issue-166/qr-samples';
  Directory(outputDir).createSync(recursive: true);

  final manifest = StringBuffer()
    ..writeln('# Mission QR Sample Manifest')
    ..writeln()
    ..writeln('| Mission Code | Title | Payload | File |')
    ..writeln('| --- | --- | --- | --- |');

  for (final sample in samples) {
    final fileName = '${sample.code}.svg';
    final svg = _qrSvg(sample.payload);
    File('$outputDir/$fileName').writeAsStringSync(svg);
    manifest.writeln(
      '| `${sample.code}` | ${sample.title} | `${sample.payload}` | `qr-samples/$fileName` |',
    );
  }

  File('../artifacts/validation/issue-166/QR_SAMPLE_MANIFEST.md')
      .writeAsStringSync(manifest.toString());
}

String _qrSvg(String payload) {
  final code = QrCode.fromData(
    data: payload,
    errorCorrectLevel: QrErrorCorrectLevel.M,
  );
  final image = QrImage(code);
  const quietZone = 4;
  const cellSize = 8;
  final moduleCount = image.moduleCount;
  final canvasSize = (moduleCount + quietZone * 2) * cellSize;
  final buffer = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$canvasSize" height="$canvasSize" viewBox="0 0 $canvasSize $canvasSize">',
    )
    ..writeln('<rect width="100%" height="100%" fill="#ffffff"/>');

  for (var row = 0; row < moduleCount; row += 1) {
    for (var col = 0; col < moduleCount; col += 1) {
      if (!image.isDark(row, col)) {
        continue;
      }
      final x = (col + quietZone) * cellSize;
      final y = (row + quietZone) * cellSize;
      buffer.writeln(
        '<rect x="$x" y="$y" width="$cellSize" height="$cellSize" fill="#111111"/>',
      );
    }
  }

  buffer.writeln('</svg>');
  return buffer.toString();
}
