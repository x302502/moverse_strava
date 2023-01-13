import 'dart:convert';
import 'package:strava_flutter/domain/model/model_authentication_response.dart';
import 'package:strava_flutter/domain/model/model_authentication_scopes.dart';
import 'package:strava_flutter/strava_client.dart';
import 'package:http/http.dart' as http;

class ActionData {
  final String name;
  final double distance;
  final String type;
  final int elapsedTime;
  final int movingTime;

  const ActionData(
      {required this.name,
      required this.distance,
      required this.type,
      required this.elapsedTime,
      required this.movingTime});

  factory ActionData.fromJson(Map<String, dynamic> json) {
    return ActionData(
        name: json['name'],
        type: json['type'],
        distance: json['distance'],
        elapsedTime: json['elapsed_time'],
        movingTime: json['moving_time']);
  }
}

class StravaService {
  final StravaClient stravaClient;
  StravaService(this.stravaClient);

  Future<TokenResponse> authentication(List<AuthenticationScope> scopes,
      String redirectUrl, String callbackUrlScheme) {
    return stravaClient.authentication.authenticate(
        scopes: scopes,
        redirectUrl: redirectUrl,
        callbackUrlScheme: callbackUrlScheme);
  }

  Future<void> deAuthorize() {
    return stravaClient.authentication.deAuthorize();
  }

  Future<List<ActionData>> fetchListAction(String? token) async {
    var headers = {
      'Authorization': 'Bearer $token',
      // 'Cookie': '_strava4_session=2m5reatrdp6ib7nekgm19gdpr3j15lab'
    };
    final response = await http.get(
        Uri.parse(
            'https://www.strava.com/api/v3/athlete/activities?page=1&per_page=30'),
        headers: headers);
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Iterable l = json.decode(response.body);
      return List<ActionData>.from(
          l.map((model) => ActionData.fromJson(model)));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }
}


// strava://oauth/mobile/authorize?client_id=100233&redirect_uri=https://moverse.app&response_type=code&approval_prompt=auto&scope=activity%3Awrite%2Cread&state=test