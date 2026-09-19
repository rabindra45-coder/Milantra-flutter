import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../services/webrtc_call_service.dart';
import '../widgets/avatar_widget.dart';

class CallScreen extends StatelessWidget {
  final Profile peer;
  final bool isVideo;

  const CallScreen({super.key, required this.peer, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    final callService = context.watch<WebRTCCallService>();

    if (callService.status == CallStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (isVideo && callService.status == CallStatus.connected)
              RTCVideoView(
                callService.remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AvatarWidget(url: peer.avatarUrl, name: peer.displayName ?? peer.username, size: 110),
                    const SizedBox(height: 24),
                    Text(
                      peer.displayName ?? peer.username ?? 'Milantra Contact',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      callService.status == CallStatus.ringingOut
                          ? 'Ringing...'
                          : callService.status == CallStatus.connecting
                              ? 'Connecting...'
                              : 'Call Active',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                    ),
                  ],
                ),
              ),
            if (isVideo && callService.status == CallStatus.connected)
              Positioned(
                top: 20,
                right: 20,
                width: 110,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RTCVideoView(
                    callService.localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            Positioned(
              bottom: 36,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: callService.isMicMuted ? LucideIcons.micOff : LucideIcons.mic,
                    isActive: callService.isMicMuted,
                    onTap: callService.toggleMic,
                  ),
                  if (isVideo)
                    _CallButton(
                      icon: LucideIcons.switchCamera,
                      onTap: callService.switchCamera,
                    ),
                  if (isVideo)
                    _CallButton(
                      icon: callService.isCameraOff ? LucideIcons.videoOff : LucideIcons.video,
                      isActive: callService.isCameraOff,
                      onTap: callService.toggleCamera,
                    ),
                  _CallButton(
                    icon: LucideIcons.phoneOff,
                    backgroundColor: Colors.red,
                    iconColor: Colors.white,
                    onTap: () {
                      callService.endCall();
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color? backgroundColor;
  final Color? iconColor;

  const _CallButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? (isActive ? Colors.white : Colors.white24),
        ),
        child: Icon(
          icon,
          color: iconColor ?? (isActive ? Colors.black : Colors.white),
          size: 26,
        ),
      ),
    );
  }
}
