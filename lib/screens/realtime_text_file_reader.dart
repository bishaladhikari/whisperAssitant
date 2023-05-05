import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spotify_ui/bloc/moviesBloc.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/message.dart';
import '../models/movie.dart';

class RealTimeTextFileReader extends StatefulWidget {
  const RealTimeTextFileReader({Key? key}) : super(key: key);

  @override
  _RealTimeTextFileReaderState createState() => _RealTimeTextFileReaderState();
}

class MovieListItem extends StatelessWidget {
  final Movie movie;

  const MovieListItem({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return ListTile(
    //   leading: Image.network(movie.posterUrl),
    //   title: Text(movie.title),
    //   subtitle: Text(movie.year),
    // );

    // add a  link to the imdb page using imdb id

    Future<void> _launchUrl(_url) async {
      if (!await launchUrl(_url)) {
        throw Exception('Could not launch $_url');
      }
    }
    return GestureDetector(
      onTap: () {
        // print(movie.imdbId);
        // open on browser
        final Uri _url = Uri.parse('https://www.imdb.com/title/${movie.imdbId}/');
        _launchUrl(_url);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => MovieDetailsPage(movie: movie),
        //   ),
        // );
      },
      child: Container(
        width: 160.0,
        child: Card(
          child: Wrap(
            children: [
              Image.network(movie.posterUrl, fit: BoxFit.cover),
              ListTile(
                title: Text(movie.title, overflow: TextOverflow.ellipsis, maxLines: 2, softWrap: false),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // add a star icon here
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.star, color:const Color(0xFFA8A800), size: 16.0),
                          Text(movie.rating??''),
                        ]),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(movie.year),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}

class _RealTimeTextFileReaderState extends State<RealTimeTextFileReader> {
  final _streamController = StreamController<String>.broadcast();
  Offset _dragOffset = Offset.zero;
  late Stream<dynamic> _stream;
  Timer? _dragTimer;
  ScrollController _scrollController = ScrollController();

  fetchMovies(imdbIds) async {
    print(imdbIds);
    List<Movie> movies = [];
    moviesBloc.drainStream();
    for (var imdbId in imdbIds) {
      final response = await http.get(Uri.parse(
          'http://www.omdbapi.com/?apikey=4547c6ef&i=$imdbId'));
      // print(response.body);
      if (response.statusCode == 200) {
        print(response.body);
         // Movie.fromJson(jsonDecode(response.body));
         movies.add(Movie.fromJson(jsonDecode(response.body)));
      } else {
        throw Exception('Failed to fetch movies');
      }
    }
    moviesBloc.movies.sink.add(movies);
    // final response = await http.get(Uri.parse(
    //     'http://www.omdbapi.com/?apikey=4547c6ef&i=$searchQuery'));
    //
    // if (response.statusCode == 200) {
    //   // final json = jsonDecode(response.body);
    //   // final List<dynamic> results = json['Search'];
    //   // final List<Movie> movies = results
    //   //     .map((result) => Movie.fromJson(result))
    //   //     .toList();
    //   // return movies;
    //   return Movie.fromJson(jsonDecode(response.body));
    // } else {
    //   throw Exception('Failed to fetch movies');
    // }
  }

  void _handleMouseEnter(PointerEvent event) {
    print('mouse entered');
    if (_dragTimer != null) {
      _dragTimer!.cancel();
      _dragTimer = null;
    }
  }
  void _handleMouseExit(PointerEvent event) {
    _dragTimer = Timer(Duration(milliseconds: 500), () {
      if (_dragOffset == Offset.zero) {
        return;
      }
      _dragOffset = Offset.zero;
      _moveWindow();
    });
  }

  void _handleMouseHover(PointerEvent event) {
    if (_dragTimer != null) {
      _dragTimer!.cancel();
      _dragTimer = null;
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _dragOffset = Offset.zero;
    _dragTimer = null;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragOffset += details.delta;
    _moveWindow();
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragOffset = Offset.zero;
    _moveWindow();
  }

  void _moveWindow() {
    if (Platform.isMacOS) {
      SystemChannels.platform.invokeMethod('MoveWindow',
          {'dx': _dragOffset.dx.toInt(), 'dy': _dragOffset.dy.toInt()});
    }
  }
  @override
  void initState() {
    super.initState();
    // Open the file for reading in binary mode
    final file = File('/Users/bishal/Documents/flutter_siri_assistant_docs/response_messages.txt');

    // Transform the stream of bytes to a stream of lines
    // _stream = stream
    //     .transform(utf8.decoder)
    //     .transform(const LineSplitter());
    // // Push each line of the file to the stream controller
    // _stream.listen((line) {
    //   print("added line");
    //   _streamController.add(line);
    //   _scrollController.jumpTo(_scrollController.position.maxScrollExtent); // add this line to scroll to bottom
    // });
    // Create a timer that will periodically check the file for changes
    var contents="";
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        // Read the contents of the file
         var new_contents = await file.readAsString();
         if(new_contents != contents){
           contents = new_contents;
           _streamController.add(new_contents);
           contents = new_contents;
           // _scrollController.jumpTo(_scrollController.position.maxScrollExtent); // add this line to scroll to bot
           WidgetsBinding.instance!.addPostFrameCallback((_) {
             _scrollController.animateTo(
               _scrollController.position.maxScrollExtent,
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOut,
             );
           });
         }

        // Add the contents to the stream
      } catch (e) {
        print('Error reading file: $e');
      }
    });
    // Future.delayed(const Duration(milliseconds: 500), () {
    //   _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    // });
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }
  var fetchedIds = [];

  @override
  Widget build(BuildContext context) {
    Color color = Colors.black;
    double strength = 0.9;
    ColorFilter colorFilter = ColorFilter.mode(color.withOpacity(strength), BlendMode.lighten);

    return MouseRegion(
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      onHover: _handleMouseHover,
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.black,
            toolbarHeight: 50,
            leading:  GestureDetector(
              onPanStart: _handleDragStart,
              onPanUpdate: _handleDragUpdate,
              onPanEnd: _handleDragEnd,
              child: Image.asset(
                'assets/AIlogo.gif',
                height: 60.0,
                width: 60.0,
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_all),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  // close the app
                  exit(0);
                },
              ),
            ],
            title: const Text('Baymax')),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // add the scroll controller
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StreamBuilder<dynamic>(
                    stream: _streamController.stream,
                    builder: (context, snapshot) {
                      // if (snapshot.hasData) {
                      //   var data = snapshot.data.toString();
                      //   print(data);
                      //   return Container(
                      //     padding: const EdgeInsets.all(16),
                      //     color: const Color(0xFF151414),
                      //       child: Text(snapshot.data!));
                      // } else {
                      //   return const Center(child: CircularProgressIndicator());
                      // }
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      // return Container();
                      List<dynamic> messages = jsonDecode(snapshot.data!)[0]['messages'];
                      print(messages.length);
                      // final List<Message> messageObjects = messages.map((json) => Message.fromJson(json)).toList();

                      // return Text(jsonArray[0]['messages'][0]['content']);
                      return Column(
                        children: [
                          for (var message in messages)
                            if (message['role'] == 'user')
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildUserMessage(Message.fromJson(message)),
                              )
                            else if (message['role'] == 'assistant')
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildAssistantMessage(Message.fromJson(message)),
                              )
                            else
                              Container(),
                        ],
                      );
                      // return SizedBox(
                      //   height: 500,
                      //   child: ListView.builder(
                      //     itemCount: messages.length,
                      //     itemBuilder: (BuildContext context, int index) {
                      //       // print(messages[index]);
                      //       final Message message = Message.fromJson(messages[index]);
                      //       // print(message.content);
                      //       print(message.role);
                      //       if (message.role == 'user') {
                      //         // return Text(message.content);
                      //         return _buildUserMessage(message);
                      //       } else if(message.role == 'assistant') {
                      //         // return Text(message.content);
                      //         return _buildAssistantMessage(message);
                      //       }
                      //       else{
                      //         return Container();
                      //       }
                      //     },
                      //   ),
                      // );
                    },
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ColorFiltered(
                  colorFilter: colorFilter,
                  child: Image.asset("assets/VAwave.gif", height: 4, width: double.infinity, fit: BoxFit.cover)),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildUserMessage(Message message) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF4E4E5E),
        child: Text('U', style: TextStyle(color: Colors.white)),
      ),
      title: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.all(10.0),
          margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF4E4E5E),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            message.content,
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      ),
    );
  }
  Widget _buildAssistantMessage(Message message) {
    var content;
    print(message.content);
    int startIndex = message.content.indexOf('{');
    int endIndex = message.content.lastIndexOf('}');

// Extract the JSON object from the string
    if(startIndex == -1 || endIndex == -1) {
      return ListTile(
        // leading: CircleAvatar(
        //   backgroundColor: const Color(0xFF4E4E5E),
        //   child: Text('A', style: TextStyle(color: Colors.white)),
        // ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.all(10.0),
            margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF8E8EE3),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              message.content,
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        ),
      );
    }
    String jsonObjectString = message.content.substring(startIndex, endIndex + 1);

// Decode the JSON object into a map
    Map<String, dynamic> jsonObject = jsonDecode(jsonObjectString);
    // if(isJson(message.content)) {
      print('is json');
      content = jsonObject['answer'];
      var json = jsonObject;
      if(json.containsKey('movies')) {
          // give a list of movies in a card slide view
        var movies = json['movies'];
        var imdbIds = [];
        for(var movie in movies) {
          imdbIds.add(movie['imdb_id']);
        }
        // if ids dont exists then push to fetchedIds
        if(imdbIds.isNotEmpty && !fetchedIds.contains(imdbIds)) {
          fetchedIds.addAll(imdbIds);
          fetchMovies(imdbIds);
        }
        // for(var movie in movies) {
        //   await fetchMovies(movie['id']);
        // }
          return Column(
            children: [
              ListTile(
                trailing: IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.content_copy, color: Colors.white38,size: 18.0),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          backgroundColor: Colors.black,
                          closeIconColor: Colors.white,
                          content: Text('Copied to clipboard', style: TextStyle(color: Colors.white),)),
                    );
                  },
                ),
              ),
              ListTile(
                title: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7CBBEC),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      jsonObject['answer'],
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 330,
                child: StreamBuilder<List<Movie>>(
                  stream: moviesBloc.movies,
                  builder: (context, snapshot) {
                    if(!snapshot.hasData)
                      return Center(child: CircularProgressIndicator());
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data?.length,
                      itemBuilder: (BuildContext context, int index) {
                        return MovieListItem(movie:snapshot.data![index]);
                        // return StreamBuilder<Object>(
                        //   stream: moviesBloc.movie,
                        //   builder: (context, snapshot) {
                        //     if(snapshot.hasData) {
                        //       return MovieListItem(movie:snapshot.data as Movie);
                        //     }
                        //     else {
                        //       return Container();
                        //     }
                        //     // return MovieListItem(movie: movie);
                        //   }
                        // );
                        // print(jsonDecode(message.content)['movies'][index]['poster_url']);
                        // var poster_url = jsonDecode(message.content)['movies'][index]['poster']??jsonDecode(message.content)['movies'][index]['poster_url'];
                        // print(poster_url);
                        // var title="";
                        // if(jsonDecode(message.content)['movies'][index]['title']!=null)
                        //   title = jsonDecode(message.content)['movies'][index]['title'];
                        // var id = jsonDecode(message.content)['movies'][index]['id'];
                        // // request omdb api for poster
                        // //4547c6ef
                        // var omdb_url = "https://www.omdbapi.com/?apikey=4a3b711b&i=$id";

                        // make an http request to that url
                        // return Container(
                        //   width: 160.0,
                        //   child: Card(
                        //     child: Wrap(
                        //       children: [
                        //         Image.network(poster_url, fit: BoxFit.cover),
                        //         ListTile(
                        //           title: Text(title),
                        //           // subtitle: Text(jsonDecode(message.content)['movies'][index]['year']),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // );
                      },
                    );
                  }
                ),
              ),
            ],
          );
      }
      if (json.containsKey('answer')) {
        return Column(
          children: [
            ListTile(
              trailing: IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.content_copy, color: Colors.white38,size: 18.0),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        backgroundColor: Colors.black,
                        closeIconColor: Colors.white,
                        content: Text('Copied to clipboard', style: TextStyle(color: Colors.white),)),
                  );
                },
              ),
            ),
            ListTile(
              title: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E8EE3),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    content.toString(),
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
              // trailing: CircleAvatar(
              //   radius: 30.0,
              //   backgroundImage: AssetImage('assets/AIlogo.gif'),
              // ),
            ),
          ],
        );
      } else if (json.containsKey('code')) {
        String code = json['code'];
        String explanation = json.containsKey('explanation') ? json['explanation'] : "";

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Code:',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: SelectableText(
                  code,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (explanation != null) ...[
                SizedBox(height: 8.0),
                Text(
                  'Explanation: $explanation',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
              SizedBox(height: 8.0),
              CircleAvatar(
                child: IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () => Clipboard.setData(ClipboardData(text: code)),
                ),
              ),
            ],
          ),
        );
      }
      else if (json.containsKey('command')) {
        return ListTile(
          title: Text(
            json['command'],
            style: TextStyle(
              fontSize: 18.0,
            ),
          ),
          subtitle: Text(
            'Run this command in the terminal.',
            style: TextStyle(fontSize: 14.0),
          ),
          trailing: CircleAvatar(
            child: Text('A'),
          ),
        );
      }
      else if (json.containsKey('askforinput')) {
        return ListTile(
          title: Text(
            json['askforinput'],
            style: TextStyle(fontSize: 18.0),
          ),
          trailing: CircleAvatar(
            child: Text('A'),
          ),
        );
      }
      else {
        return SizedBox.shrink();
      }
    // }
    content = message.content;
    return Column(
      children: [
        ListTile(
          trailing: IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.content_copy, color: Colors.white38,size: 18.0),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    backgroundColor: Colors.black,
                    closeIconColor: Colors.white,
                    content: Text('Copied to clipboard', style: TextStyle(color: Colors.white),)),
              );
            },
          ),
        ),
        ListTile(
          title: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.all(10.0),
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              decoration: BoxDecoration(
                color: const Color(0xFF8E8EE3),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                content.toString(),
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ),
          // trailing: CircleAvatar(
          //   radius: 30.0,
          //   backgroundImage: AssetImage('assets/AIlogo.gif'),
          // ),
        ),
      ],
    );
    // Map<String, dynamic> json = jsonDecode(message.content);
    //
    // if (json.containsKey('answer')) {
    //   return ListTile(
    //     title: Text(
    //       json['answer'],
    //       style: TextStyle(fontSize: 18.0),
    //     ),
    //       trailing: CircleAvatar(
    //         backgroundImage: AssetImage('assets/AIlogo.gif'),
    //       ),
    //   );
    // } else if (json.containsKey('code')) {
    //   return Padding(
    //     padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text(
    //           'Code:',
    //           style: TextStyle(
    //             fontSize: 18.0,
    //             fontWeight: FontWeight.bold,
    //           ),
    //         ),
    //         SizedBox(height: 8.0),
    //         Container(
    //           decoration: BoxDecoration(
    //             color: Colors.grey[200],
    //             borderRadius: BorderRadius.circular(4.0),
    //           ),
    //           child: Padding(
    //             padding: EdgeInsets.all(8.0),
    //             child: Text(
    //               json['code'],
    //               style: TextStyle(fontSize: 14.0),
    //             ),
    //           ),
    //         ),
    //         SizedBox(height: 8.0),
    //         if (json.containsKey('explanation'))
    //           Text(
    //             'Explanation: ${json['explanation']}',
    //             style: TextStyle(fontSize: 16.0),
    //           ),
    //         SizedBox(height: 8.0),
    //         CircleAvatar(
    //           child: Text('A'),
    //         ),
    //       ],
    //     ),
    //   );
    // } else if (json.containsKey('command')) {
    //   return ListTile(
    //     title: Text(
    //       json['command'],
    //       style: TextStyle(
    //         fontSize: 18.0,
    //       ),
    //     ),
    //     subtitle: Text(
    //       'Run this command in the terminal.',
    //       style: TextStyle(fontSize: 14.0),
    //     ),
    //     trailing: CircleAvatar(
    //       child: Text('A'),
    //     ),
    //   );
    // } else if (json.containsKey('askforinput')) {
    //   return ListTile(
    //     title: Text(
    //       json['askforinput'],
    //       style: TextStyle(fontSize: 18.0),
    //     ),
    //     trailing: CircleAvatar(
    //       child: Text('A'),
    //     ),
    //   );
    // } else {
    //   return SizedBox.shrink();
    // }
  }

  bool isJson(String content) {
    try {
      jsonDecode(content);
      return true;
    } catch (e) {
      return false;
    }
  }
}