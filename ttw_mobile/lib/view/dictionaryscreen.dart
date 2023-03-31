import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../model/user.dart';
import 'mainscreen.dart';

User user = User();

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DictionaryScreen(
        user: user,
      ),
    );
  }
}

class DictionaryScreen extends StatefulWidget {
  final User user;
  const DictionaryScreen({super.key, required this.user});

  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final String _url = "https://owlbot.info/api/v4/dictionary/";
  final String _token = "78a5f282b05342e425dbd662e06500e2d760b06f";

  final TextEditingController _controller = TextEditingController();

  late StreamController _streamController;
  late Stream _stream;

  late Timer _debounce;

  final border = const OutlineInputBorder(
      borderRadius: BorderRadius.horizontal(left: Radius.circular(24.0)));

  void clearText() {
    _controller.clear();
  }

  _search() async {
    if (_controller.text == null || _controller.text.length == 0) {
      _streamController.add(null);
      return;
    }

    _streamController.add("waiting");
    Response response = await get(Uri.parse(_url + _controller.text.trim()),
        headers: {"Authorization": "Token " + _token});
    _streamController.add(json.decode(response.body));
  }

  @override
  void initState() {
    super.initState();

    _streamController = StreamController();
    _stream = _streamController.stream;
    _debounce = Timer(const Duration(milliseconds: 1000), () {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dictionary"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Row(
            children: <Widget>[
              IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (content) => MainScreen(
                                  user: user,
                                )));
                  }),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(
                      left: 8.0, bottom: 8.0, right: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: TextFormField(
                    onChanged: (String text) {
                      if (_debounce?.isActive ?? false) _debounce.cancel();
                      _debounce = Timer(const Duration(milliseconds: 1000), () {
                        _search();
                      });
                    },
                    controller: _controller,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                      hintText: "Search for a word",
                      border: InputBorder.none,
                      prefixIcon: IconButton(
                        onPressed: () {
                          _search();
                        },
                        icon: const Icon(Icons.search),
                      ),
                      suffixIcon: SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: clearText,
                              icon: const Icon(Icons.clear),
                            ),
                            IconButton(
                              onPressed: () {
                                print('mic button pressed');
                              },
                              icon: const Icon(Icons.mic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // IconButton(
              //   icon: const Icon(
              //     Icons.search,
              //     color: Colors.white,
              //   ),
              //   onPressed: () {
              //     _search();
              //   },
              // )
            ],
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(8.0),
        child: StreamBuilder(
          stream: _stream,
          builder: (BuildContext ctx, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return const Center(
                child: Text("Enter a search word"),
              );
            }

            if (snapshot.data == "waiting") {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data["definitions"].length,
              itemBuilder: (BuildContext context, int index) {
                return ListBody(
                  children: <Widget>[
                    Container(
                      color: Colors.grey[300],
                      child: ListTile(
                        leading: snapshot.data["definitions"][index]
                                    ["image_url"] ==
                                null
                            ? null
                            : CircleAvatar(
                                backgroundImage: NetworkImage(snapshot
                                    .data["definitions"][index]["image_url"]),
                              ),
                        title: Text(_controller.text.trim() +
                            "(" +
                            snapshot.data["definitions"][index]["type"] +
                            ")"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          snapshot.data["definitions"][index]["definition"]),
                    )
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
