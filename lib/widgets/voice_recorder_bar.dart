import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../core/constants.dart';

class VoiceRecorderBar extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(File file, int durationSeconds) onRecorded;

  const VoiceRecorderBar({super.key, required this.onCancel, required this.onRecorded});

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar> {
  final AudioRecorder _recorder = AudioRecorder();
  int _seconds = 0;
  bool _isRecording = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      widget.onCancel();
      return;
    }

    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _filePath!,
    );

    setState(() => _isRecording = true);
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isRecording) {
        setState(() => _seconds++);
        _tick();
      }
    });
  }

  Future<void> _stopAndSend() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path != null && _seconds >= 1) {
      widget.onRecorded(File(path), _seconds);
    } else {
      widget.onCancel();
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          const Icon(LucideIcons.mic, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Text(
            '${(_seconds ~/ 60).toString().padLeft(2, "0")}:${(_seconds % 60).toString().padLeft(2, "0")}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              await _recorder.stop();
              widget.onCancel();
            },
            child: const Text('Cancel'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.send, color: AppColors.brandPrimary),
            onPressed: _stopAndSend,
          ),
        ],
      ),
    );
  }
}
