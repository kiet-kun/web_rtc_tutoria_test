//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import './signaling.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Signaling signaling = Signaling();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');

  @override
  void initState() {
    //_localRenderer.initialize();
    _remoteRenderer.initialize();

    // signaling.onAddRemoteStream = ((stream) {
    //   _remoteRenderer.srcObject = stream;
    //   setState(() {});
    // });

    super.initState();

    initRenderers();
  }

  initRenderers() async {
    await _localRenderer.initialize();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  final Map<String, dynamic> mediaConstraints = {
    "audio": true,
    //"video": true,
    "video": {
      "mandatory": {
        "minWidth":
            '1280', // Provide your own width, height and frame rate here
        "minHeight": '720',
        "minFrameRate": '30',
      },
      "facingMode": "user",
      "optional": [],
    }
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome to Flutter Explained - WebRTC"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                //signaling.openUserMedia(_localRenderer, _remoteRenderer);
                //signaling.openUserMedia(_localRenderer);
                MediaStream _localstream =
                    await navigator.getUserMedia(mediaConstraints);

                _localRenderer.srcObject = _localstream;
              },
              child: Text("Open camera & microphone"),
            ),
            SizedBox(
              width: 8,
            ),
            ElevatedButton(
              onPressed: () async {
                // roomId = await signaling.createRoom(_remoteRenderer);
                // textEditingController.text = roomId!;
                // setState(() {});
              },
              child: Text("Create room"),
            ),
            SizedBox(
              width: 8,
            ),
            ElevatedButton(
              onPressed: () {
                // Add roomId
                // signaling.joinRoom(
                //   textEditingController.text,
                //   _remoteRenderer,
                // );
              },
              child: Text("Join room"),
            ),
            SizedBox(
              width: 8,
            ),
            ElevatedButton(
              onPressed: () {
                //signaling.hangUp(_localRenderer);
              },
              child: Text("Hangup"),
            ),
            SizedBox(height: 8),
            Container(
              color: Colors.amber,
              margin: EdgeInsets.all(9),
              width: 150.0,
              height: 200.0,
              child: RTCVideoView(_localRenderer),
            ),

            // Expanded(
            //   child: Padding(
            //     padding: const EdgeInsets.all(8.0),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
            //         //Expanded(child: RTCVideoView(_remoteRenderer)),
            //       ],
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Join the following Room: "),
                  Flexible(
                    child: TextFormField(
                      controller: textEditingController,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 8)
          ],
        ),
      ),
    );
  }
}
