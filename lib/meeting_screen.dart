import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:peerdart/peerdart.dart';
import 'package:flutter/material.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  MediaStream? _localStream;
  bool _inCalling = false;
  bool _isTorchOn = false;
  MediaRecorder? _mediaRecorder;
  bool get _isRec => _mediaRecorder != null;
  List<MediaDeviceInfo>? _mediaDevicesList;
  bool isVideo = true;
  bool isAudio = true;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  final TextEditingController _controller = TextEditingController();
  final Peer peer = Peer(options: PeerOptions(debug: LogLevel.All));
  bool inCall = false;
  String? peerId;
  bool videoEnabled = true;
  bool audioEnabled = true;

  bool toggleVideo() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      if (videoTrack != null) {
        final bool videoEnabled = videoTrack.enabled = !videoTrack.enabled;
        this.videoEnabled = videoEnabled;
        // sendMessage('video-toggle', {
        //   'userId': this.userId,
        //   'videoEnabled': videoEnabled,
        // });
        return videoEnabled;
      }
    }
    return false;
  }

  bool toggleAudio() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks()[0];
      if (audioTrack != null) {
        final bool audioEnabled = audioTrack.enabled = !audioTrack.enabled;
        this.audioEnabled = audioEnabled;
        // sendMessage('audio-toggle', {
        //   'userId': this.userId,
        //   'audioEnabled': audioEnabled,
        // });
        return audioEnabled;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    initRenderers();
    navigator.mediaDevices.ondevicechange = (event) async {
      print('++++++ ondevicechange ++++++');
      _mediaDevicesList = await navigator.mediaDevices.enumerateDevices();
    };
  }

  @override
  void dispose() {
    peer.dispose();
    _controller.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_inCalling) {
      _hangUp();
    }
    _localRenderer.dispose();
    navigator.mediaDevices.ondevicechange = null;
  }

  void initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    peer.on("open").listen((id) {
      setState(() {
        peerId = peer.id;
      });
    });

    final mediaStream = await navigator.mediaDevices
        .getUserMedia({"video": isVideo, "audio": isAudio});
    _mediaDevicesList = await navigator.mediaDevices.enumerateDevices();
    _localStream = mediaStream;

    peer.on<MediaConnection>("call").listen((call) async {
      // final mediaConstraints = <String, dynamic>{
      //   'audio': isAudio,
      //   'video': isVideo,
      // };

      // var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      // _mediaDevicesList = await navigator.mediaDevices.enumerateDevices();
      // _localStream = stream;
      // _localRenderer.srcObject = _localStream;

      // var mediaConstraints = <String, dynamic>{
      //   'audio': isAudio,
      //   'video': {
      //     'mandatory': {
      //       'minWidth':
      //           '640', // Provide your own width, height and frame rate here
      //       'minHeight': '480',
      //       'minFrameRate': '30',
      //     },
      //     'facingMode': 'user',
      //     'optional': [],
      //   }
      // };

      // if (isVideo == false) {
      //   mediaConstraints = <String, dynamic>{
      //     'audio': isAudio,
      //     'video': false,
      //   };
      // }

      // final mediaStream = await navigator.mediaDevices
      //     .getUserMedia({"video": isVideo, "audio": isAudio});

      // final mediaStream =
      //     await navigator.mediaDevices.getUserMedia(mediaConstraints);

      call.answer(mediaStream);

      call.on("close").listen((event) {
        setState(() {
          inCall = false;
        });
        endMeeting();
      });

      call.on<MediaStream>("stream").listen((event) {
        _localRenderer.srcObject = mediaStream;
        _remoteRenderer.srcObject = event;

        setState(() {
          inCall = true;
          _inCalling = true;
        });
      });
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _makeCall() async {
    // peer.on<MediaConnection>("call").listen((call) async {
    //   final mediaStream = await navigator.mediaDevices
    //       .getUserMedia({"video": isVideo, "audio": isAudio});

    //   call.answer(mediaStream);

    //   call.on("close").listen((event) {
    //     setState(() {
    //       inCall = false;
    //     });
    //   });

    //   call.on<MediaStream>("stream").listen((event) {
    //     _localRenderer.srcObject = mediaStream;
    //     _remoteRenderer.srcObject = event;

    //     setState(() {
    //       inCall = true;
    //     });
    //   });
    // });

    var mediaConstraints = <String, dynamic>{
      'audio': isAudio,
      'video': {
        'mandatory': {
          'minWidth':
              '640', // Provide your own width, height and frame rate here
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    if (isVideo == false) {
      mediaConstraints = <String, dynamic>{
        'audio': isAudio,
        'video': false,
      };
    }

    // final mediaConstraints = <String, dynamic>{
    //   'audio': isAudio,
    //   'video': isVideo,
    // };

    try {
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _mediaDevicesList = await navigator.mediaDevices.enumerateDevices();
      _localStream = stream;
      _localRenderer.srcObject = _localStream;

      final conn = peer.call(_controller.text, stream);

      conn.on("close").listen((event) {
        setState(() {
          inCall = false;
        });
      });

      conn.on<MediaStream>("stream").listen((event) {
        _remoteRenderer.srcObject = event;
        _localRenderer.srcObject = stream;

        setState(() {
          inCall = true;
          _inCalling = true;
        });
      });
    } catch (e) {
      print(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _inCalling = true;
    });
  }

  Future<void> _hangUp() async {
    try {
      if (kIsWeb) {
        _localStream?.getTracks().forEach((track) => track.stop());
      }
      await _localStream?.dispose();
      _localRenderer.srcObject = null;
      setState(() {
        _inCalling = false;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // void _startRecording() async {
  //   if (_localStream == null) throw Exception('Stream is not initialized');
  //   if (Platform.isIOS) {
  //     print('Recording is not available on iOS');
  //     return;
  //   }
  //   // TODO(rostopira): request write storage permission
  //   final storagePath = await getExternalStorageDirectory();
  //   if (storagePath == null) throw Exception('Can\'t find storagePath');

  //   final filePath = storagePath.path + '/webrtc_sample/test.mp4';
  //   _mediaRecorder = MediaRecorder();
  //   setState(() {});

  //   final videoTrack = _localStream!
  //       .getVideoTracks()
  //       .firstWhere((track) => track.kind == 'video');
  //   await _mediaRecorder!.start(
  //     filePath,
  //     videoTrack: videoTrack,
  //   );
  // }

  // void _stopRecording() async {
  //   await _mediaRecorder?.stop();
  //   setState(() {
  //     _mediaRecorder = null;
  //   });
  // }

  // void _toggleTorch() async {
  //   if (_localStream == null) throw Exception('Stream is not initialized');

  //   final videoTrack = _localStream!
  //       .getVideoTracks()
  //       .firstWhere((track) => track.kind == 'video');
  //   final has = await videoTrack.hasTorch();
  //   if (has) {
  //     print('[TORCH] Current camera supports torch mode');
  //     setState(() => _isTorchOn = !_isTorchOn);
  //     await videoTrack.setTorch(_isTorchOn);
  //     print('[TORCH] Torch state is now ${_isTorchOn ? 'on' : 'off'}');
  //   } else {
  //     print('[TORCH] Current camera does not support torch mode');
  //   }
  // }

  void _toggleCamera() async {
    if (_localStream == null) throw Exception('Stream is not initialized');

    final videoTrack = _localStream!
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    await Helper.switchCamera(videoTrack);
  }

  // void _captureFrame() async {
  //   if (_localStream == null) throw Exception('Stream is not initialized');

  //   final videoTrack = _localStream!
  //       .getVideoTracks()
  //       .firstWhere((track) => track.kind == 'video');
  //   final frame = await videoTrack.captureFrame();
  //   await showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //             content:
  //                 Image.memory(frame.asUint8List(), height: 720, width: 1280),
  //             actions: <Widget>[
  //               TextButton(
  //                 onPressed: Navigator.of(context, rootNavigator: true).pop,
  //                 child: Text('OK'),
  //               )
  //             ],
  //           ));
  // }

  void endMeeting() {
    _hangUp();
    peer.dispose();
    //_controller.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            endMeeting();
          },
        ),
        actions: _inCalling
            ? <Widget>[
                IconButton(
                  icon: Icon(isVideo ? Icons.videocam : Icons.videocam_off),
                  onPressed: () {
                    setState(() {
                      isVideo = !isVideo;
                    });
                    toggleVideo();
                  },
                ),
                IconButton(
                  icon: Icon(isAudio ? Icons.mic : Icons.mic_off),
                  onPressed: () {
                    setState(() {
                      isAudio = !isAudio;
                    });
                    toggleAudio();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.switch_video),
                  onPressed: _toggleCamera,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Connection ID:',
            ),
            SelectableText(peerId ?? ""),
            TextField(
              controller: _controller,
            ),
            ElevatedButton(
              onPressed: () {
                _makeCall();
              },
              child: Text('Call'),
            ),
            ElevatedButton(
              onPressed: () {
                endMeeting();
              },
              child: Text('HangUp'),
            ),
            (isVideo)
                ? Container(
                    margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                    width: 200,
                    height: 250,
                    decoration: BoxDecoration(color: Colors.black54),
                    child: RTCVideoView(_localRenderer, mirror: true),
                  )
                : Text('No video'),
            Container(
              margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
              width: 200,
              height: 250,
              decoration: BoxDecoration(color: Colors.black54),
              child: RTCVideoView(_remoteRenderer, mirror: true),
            ),
          ],
        ),
      ),
    );
  }
}
