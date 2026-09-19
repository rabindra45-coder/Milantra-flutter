import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/profile.dart';
import 'supabase_service.dart';

enum CallStatus { idle, ringingOut, ringingIn, connecting, connected, ended }

class WebRTCCallService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  CallStatus status = CallStatus.idle;
  bool isVideo = false;
  String? currentConversationId;
  String? peerId;
  Profile? peerProfile;

  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  bool isMicMuted = false;
  bool isCameraOff = false;
  bool isSpeakerOn = true;
  bool isFrontCamera = true;

  RealtimeChannel? _callChannel;
  String? activeCallLogId;

  WebRTCCallService() {
    _initRenderers();
    _listenIncomingSignaling();
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  void _listenIncomingSignaling() {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    _callChannel = _client.channel('calls:$myId');
    _callChannel!.onBroadcast(event: 'signal', callback: (payload) async {
      final type = payload['type'];
      final from = payload['from'] as String;

      if (type == 'invite') {
        if (status != CallStatus.idle) {
          _sendSignal(from, {'type': 'decline', 'from': myId});
          return;
        }
        peerId = from;
        isVideo = payload['video'] as bool? ?? false;
        currentConversationId = payload['conversationId'] as String?;
        status = CallStatus.ringingIn;
        notifyListeners();
      } else if (type == 'answer') {
        final sdp = payload['sdp'];
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(sdp['sdp'], sdp['type']),
        );
        status = CallStatus.connected;
        notifyListeners();
      } else if (type == 'ice') {
        final candidate = payload['candidate'];
        if (candidate != null) {
          await _peerConnection?.addCandidate(
            RTCIceCandidate(
              candidate['candidate'],
              candidate['sdpMid'],
              candidate['sdpMLineIndex'],
            ),
          );
        }
      } else if (type == 'decline' || type == 'hangup') {
        endCall();
      }
    }).subscribe();
  }

  Future<void> startCall({
    required String conversationId,
    required Profile targetUser,
    required bool video,
  }) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    peerId = targetUser.id;
    peerProfile = targetUser;
    isVideo = video;
    currentConversationId = conversationId;
    status = CallStatus.ringingOut;
    notifyListeners();

    final callRes = await _client.from('calls').insert({
      'conversation_id': conversationId,
      'caller_id': myId,
      'callee_id': targetUser.id,
      'kind': video ? 'video' : 'audio',
      'status': 'ringing',
    }).select('id').single();
    activeCallLogId = callRes['id'] as String;

    await _initPeerConnection();
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _sendSignal(targetUser.id, {
      'type': 'invite',
      'from': myId,
      'conversationId': conversationId,
      'video': video,
      'sdp': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  Future<void> acceptCall() async {
    if (peerId == null) return;
    status = CallStatus.connecting;
    notifyListeners();

    await _initPeerConnection();
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    final myId = _client.auth.currentUser?.id;
    _sendSignal(peerId!, {
      'type': 'answer',
      'from': myId,
      'sdp': {'sdp': answer.sdp, 'type': answer.type},
    });

    status = CallStatus.connected;
    notifyListeners();
  }

  Future<void> _initPeerConnection() async {
    _peerConnection = await createPeerConnection(AppConstants.rtcIceServers);

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localRenderer.srcObject = localStream;

    localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, localStream!);
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (peerId != null && candidate != null) {
        final myId = _client.auth.currentUser?.id;
        _sendSignal(peerId!, {
          'type': 'ice',
          'from': myId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        remoteRenderer.srcObject = remoteStream;
        notifyListeners();
      }
    };
  }

  void _sendSignal(String toUserId, Map<String, dynamic> payload) {
    _client.channel('calls:$toUserId').sendBroadcastMessage(
      event: 'signal',
      payload: payload,
    );
  }

  void toggleMic() {
    if (localStream != null) {
      final audioTrack = localStream!.getAudioTracks().firstOrNull;
      if (audioTrack != null) {
        audioTrack.enabled = !audioTrack.enabled;
        isMicMuted = !audioTrack.enabled;
        notifyListeners();
      }
    }
  }

  void toggleCamera() {
    if (localStream != null) {
      final videoTrack = localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        videoTrack.enabled = !videoTrack.enabled;
        isCameraOff = !videoTrack.enabled;
        notifyListeners();
      }
    }
  }

  void switchCamera() {
    if (localStream != null && isVideo) {
      Helper.switchCamera(localStream!.getVideoTracks().first);
      isFrontCamera = !isFrontCamera;
      notifyListeners();
    }
  }

  void endCall() {
    if (peerId != null) {
      final myId = _client.auth.currentUser?.id;
      _sendSignal(peerId!, {'type': 'hangup', 'from': myId});
    }

    localStream?.getTracks().forEach((t) => t.stop());
    remoteStream?.getTracks().forEach((t) => t.stop());
    _peerConnection?.close();
    _peerConnection = null;

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;

    status = CallStatus.idle;
    peerId = null;
    peerProfile = null;
    activeCallLogId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    _callChannel?.unsubscribe();
    super.dispose();
  }
}
