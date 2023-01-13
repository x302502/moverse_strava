import 'dart:async';

import 'package:moverse_app/strava/strava_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:strava_flutter/domain/model/model_authentication_response.dart';
import 'package:strava_flutter/domain/model/model_authentication_scopes.dart';
import 'package:strava_flutter/domain/model/model_fault.dart';
import 'package:strava_flutter/strava_client.dart';
import 'secret.dart';

void main() => runApp(MyApp());

const titleApp = 'Moverse Strava';
const String redirectUrl = "moverse.app://moverse.app";
const String callbackUrlScheme = "moverse.app";

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: titleApp,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StravaFlutterPage(),
    );
  }
}

class StravaFlutterPage extends StatefulWidget {
  @override
  _StravaFlutterPageState createState() => _StravaFlutterPageState();
}

class _StravaFlutterPageState extends State<StravaFlutterPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final DateFormat dateFormatter = DateFormat("HH:mm:ss");
  late final StravaClient stravaClient;

  bool isLoggedIn = false;
  TokenResponse? token;
  List<ActionData> data = [];

  @override
  void initState() {
    stravaClient = StravaClient(secret: secret, clientId: clientId);
    //  data.add(new ActionData(name: 'Test01', distance: 111.2, type: 'Walk'));
    super.initState();
  }

  FutureOr<Null> showErrorMessage(dynamic error, dynamic stackTrace) {
    if (error is Fault) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Did Receive Fault"),
              content: Text(
                  "Message: ${error.message}\n-----------------\nErrors:\n${(error.errors ?? []).map((e) => "Code: ${e.code}\nResource: ${e.resource}\nField: ${e.field}\n").toList().join("\n----------\n")}"),
            );
          });
    }
  }

  void authentication() {
    StravaService(stravaClient).authentication([
      AuthenticationScope.profile_read_all,
      AuthenticationScope.read_all,
      AuthenticationScope.activity_read_all
    ], redirectUrl, callbackUrlScheme).then((token) {
      setState(() {
        isLoggedIn = true;
        this.token = token;
      });
      _textEditingController.text = token.accessToken;
    }).catchError(showErrorMessage);
  }

  void loadData() async {
    try {
      List<ActionData> res =
          await StravaService(stravaClient).fetchListAction(token?.accessToken);
      setState(() {
        data = res;
      });
    } catch (e) {
      showErrorMessage(e, e.toString());
    }
  }

  void testDeauth() {
    StravaService(stravaClient).deAuthorize().then((value) {
      setState(() {
        isLoggedIn = false;
        token = null;
        _textEditingController.clear();
      });
    }).catchError(showErrorMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(titleApp),
        actions: [
          Icon(
            isLoggedIn
                ? Icons.radio_button_checked_outlined
                : Icons.radio_button_off,
            color: isLoggedIn ? Colors.white : Colors.red,
          ),
          // ignore: prefer_const_constructors
          SizedBox(
            width: 8,
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_login(), Expanded(child: _listHistory())],
        ),
      ),
    );
  }

  Widget _login() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              child: Text("Link"),
              onPressed: authentication,
            ),
            ElevatedButton(
              child: Text("Unlink"),
              onPressed: testDeauth,
            ),
          ],
        ),
        SizedBox(
          height: 8,
        ),
        // TextField(
        //   minLines: 1,
        //   maxLines: 3,
        //   controller: _textEditingController,
        //   decoration: InputDecoration(
        //       border: OutlineInputBorder(),
        //       label: Text("Access Token"),
        //       suffixIcon: TextButton(
        //         child: Text("Copy"),
        //         onPressed: () {
        //           Clipboard.setData(
        //                   ClipboardData(text: _textEditingController.text))
        //               .then((value) =>
        //                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //                     content: Text("Copied!"),
        //                   )));
        //         },
        //       )),
        // ),
        Center(
          child: TextButton(
            child: token != null && token?.accessToken != null
                ? Text(
                    'Connected',
                    style: TextStyle(color: Colors.green),
                  )
                : Text(
                    'Unconnected',
                    style: TextStyle(color: Colors.black),
                  ),
            onPressed: () {},
          ),
        ),
        Divider(),
        ElevatedButton(
          child: Text("Load history"),
          onPressed: loadData,
        ),
        Divider()
      ],
    );
  }

  Card buildCard(ActionData item) {
    const style01 = TextStyle(fontSize: 14);
    const style02 = TextStyle(fontWeight: FontWeight.bold);
    const cardImage = NetworkImage(
        'https://d3o5xota0a1fcr.cloudfront.net/v6/maps/IGPGBKBSLOJZ3CKKEVAGONGX7BLKHDGFMQCGEVGDRFAOHSOO4ZEJIARDW3QZUC6AO6IRMGYSOXKUVCWJFQVYUWCNA7P5GZB4');
    return Card(
        elevation: 4.0,
        child: Column(
          children: [
            ListTile(
              title: Text(item.name),
              subtitle: Text('${item.distance} m'),
              trailing: Icon(Icons.favorite_outline),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RichText(
                  text: TextSpan(
                    text: '',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(text: 'Distance \n', style: style01),
                      TextSpan(
                        text: '${item.distance} m',
                        style: style02,
                      )
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: '',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(text: 'Type \n', style: style01),
                      TextSpan(
                        text: '${item.type}',
                        style: style02,
                      )
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: '',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(text: ' \n', style: TextStyle(fontSize: 14)),
                      TextSpan(
                        text: '${item.distance}',
                        style: style02,
                      )
                    ],
                  ),
                ),
              ],
            ),
            Divider(
              height: 10,
            ),
            Container(
              height: 200.0,
              child: Ink.image(
                image: cardImage,
                fit: BoxFit.cover,
              ),
            ),
            // Container(
            //   padding: EdgeInsets.all(16.0),
            //   alignment: Alignment.centerLeft,
            //   child: Text(''),
            // ),
            ButtonBar(
              children: [
                TextButton(
                  child: const Text('Share'),
                  onPressed: () {/* ... */},
                ),
                // TextButton(
                //   child: const Text('LEARN MORE'),
                //   onPressed: () {/* ... */},
                // )
              ],
            )
          ],
        ));
  }

  Widget _listHistory() {
    // ListView.builder(
    //   itemBuilder: (ctx, idx) {
    //     return buildCard(data[idx]);
    //   },
    //   itemCount: data.length,
    // );
    return Container(
      child: ListView(
        children: [
          for (ActionData item in data) buildCard(item),
        ],
      ),
    );
  }
}
