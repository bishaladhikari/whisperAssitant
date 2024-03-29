import 'dart:io';

import 'package:dart_openai/openai.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spotify_ui/bloc/transcriptBloc.dart';
import 'package:flutter_spotify_ui/data/data.dart';
import 'package:flutter_spotify_ui/models/current_track_model.dart';
import 'package:flutter_spotify_ui/screens/playlist_screen.dart';
import 'package:flutter_spotify_ui/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:web_socket_channel/io.dart';
void main() async {
  final channel = IOWebSocketChannel.connect('ws://localhost:8766');

  channel.stream.listen((message) async {
    transcriptBloc.transcriptText.sink.add(message);
    // OpenAI.apiKey = "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";
    // Stream<OpenAIStreamChatCompletionModel> chatStream = OpenAI.instance.chat.createStream(
    //   model: "gpt-3.5-turbo",
    //   message.dart: [
    //     OpenAIChatCompletionChoiceMessageModel(
    //       content: message,
    //       role: OpenAIChatMessageRole.user,
    //     )
    //   ],
    // );
    //
    // var wholeText = "";
    // await for (var chatStreamEvent in chatStream) {
    //   var newContent = chatStreamEvent.choices[0].delta.content ?? "";
    //   wholeText += newContent;
    //   transcriptBloc.transcriptText.sink.add(wholeText);
    //   print(newContent);
    // }

    // Use the "say" command to speak the whole text
    // await Process.run('say', [wholeText]);
    print('Received message: $message');
  });

  // final mic = new MicrophoneStream();
  //
  // await mic.initialize();
  // mic.pipe(channel.sink);
  //
  // await Future.delayed(Duration(minutes: 10));
  // await mic.close();

  channel.sink.add('Hello, Voice assistant, I am client from flutter!');


  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
    await DesktopWindow.setMinWindowSize(const Size(600, 800));
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => CurrentTrackModel(),
      child: MyApp(channel: channel),
    ),
  );
}

class MyApp extends StatelessWidget {
  var channel;
  MyApp({this.channel});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Voice Assistant',
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        scaffoldBackgroundColor: const Color(0xFF121212),
        backgroundColor: const Color(0xFF121212),
        primaryColor: Colors.black,
        accentColor: const Color(0xFF1DB954),
        iconTheme: const IconThemeData().copyWith(color: Colors.white),
        fontFamily: 'Montserrat',
        textTheme: TextTheme(
          headline2: const TextStyle(
            color: Colors.white,
            fontSize: 32.0,
            fontWeight: FontWeight.bold,
          ),
          headline4: TextStyle(
            fontSize: 12.0,
            color: Colors.grey[300],
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0,
          ),
          bodyText1: TextStyle(
            color: Colors.grey[300],
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
          bodyText2: TextStyle(
            color: Colors.grey[300],
            letterSpacing: 1.0,
          ),
        ),
      ),
      home: Shell(channel: channel),
        themeMode: ThemeMode.dark
    );
  }
}

class Shell extends StatelessWidget {
  var channel;
  Shell({this.channel});
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                if (MediaQuery.of(context).size.width > 800) SideMenu(),
                const Expanded(
                  child: PlaylistScreen(playlist: lofihiphopPlaylist),
                ),
              ],
            ),
          ),
          CurrentTrack(),
          // StreamBuilder(
          //   stream: channel.stream,
          //   builder: (context, snapshot) {
          //     return Text(snapshot.hasData ? '${snapshot.data}' : '');
          //   },
          // )
        ],
      ),
    );
  }
}
