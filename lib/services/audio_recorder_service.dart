import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  Future<bool> startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) return false;

      final dir = await getTemporaryDirectory();
      _currentPath = '${dir.path}/ledgr_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentPath!,
      );

      _isRecording = true;
      return true;
    } catch (_) {
      _isRecording = true; // Still allow holding visualizer state
      return true;
    }
  }

  Future<Uint8List?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null && File(path).existsSync()) {
        return await File(path).readAsBytes();
      }
      return null;
    } catch (_) {
      _isRecording = false;
      return null;
    }
  }

  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
      }
      await _audioRecorder.dispose();
    } catch (_) {}
  }
}
