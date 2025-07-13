import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyManager {
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<void> saveSpotifyToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spotify_access_token', token);
  }

  Future<void> logoutFromSpotify() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_access_token');
  }

  Future<String> getSpotifyUserId(String token) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id']; // <- este é o userId
    } else {
      throw Exception('Erro ao obter o userId: ${response.body}');
    }
  }

  Future<void> createAndOpenSpotifyPlaylist(String userId, List<String> trackUris, String token, String playlistName) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Criar playlist
    final createRes = await http.post(
      Uri.parse('https://api.spotify.com/v1/users/$userId/playlists'),
      headers: headers,
      body: jsonEncode({
        'name': playlistName,
        'public': false,
      }),
    );

    final playlistId = jsonDecode(createRes.body)['id'];

    // Adicionar músicas
    await http.post(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
      headers: headers,
      body: jsonEncode({
        'uris': trackUris, // Ex: ['spotify:track:ID1', 'spotify:track:ID2']
      }),
    );

    // Abrir no app Spotify
    final playlistUrl = 'https://open.spotify.com/playlist/$playlistId';
    await launchUrl(
      Uri.parse(playlistUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<String?> authenticateWithSpotify() async {
    final clientId = '7ef38e7a542a41979001c6f52fb05c14';
    final redirectUri = 'tunetap://callback';
    final scopes =
        'playlist-modify-public playlist-modify-private user-read-private';

    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final authUrl =
        'https://accounts.spotify.com/authorize'
        '?response_type=code'
        '&client_id=$clientId'
        '&redirect_uri=$redirectUri'
        '&scope=$scopes'
        '&code_challenge=$codeChallenge'
        '&code_challenge_method=S256';


    final completer = Completer<String?>();
    final appLinks = AppLinks();
    StreamSubscription? _linkSubscription;


    if (!await launchUrl(
      Uri.parse(authUrl),
      mode: LaunchMode.externalApplication,
    )) {
      print('Não foi possível abrir o navegador');
      completer.complete(null);
      return completer.future;
    }

    _linkSubscription = appLinks.uriLinkStream.listen(
      (Uri? uri) async {
        if (uri != null && uri.queryParameters.containsKey('code')) {
          final code = uri.queryParameters['code'];
          print('Código de autorização: $code');

          final tokenResponse = await http.post(
            Uri.parse('https://accounts.spotify.com/api/token'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'grant_type': 'authorization_code',
              'code': code!,
              'redirect_uri': redirectUri,
              'client_id': clientId,
              'code_verifier': codeVerifier,
            },
          );

          if (tokenResponse.statusCode == 200) {
            final json = jsonDecode(tokenResponse.body);
            final token = json['access_token'];
            print('Token de acesso obtido: $token');
            _linkSubscription?.cancel();
            completer.complete(token);
          } else {
            print('Erro ao trocar o código por token: ${tokenResponse.body}');
            _linkSubscription?.cancel();
            completer.complete(null);
          }
        }
      },
      onError: (err) {
        print('Erro ao escutar links: $err');
        _linkSubscription?.cancel();
        completer.complete(null);
      },
    );
    return completer.future;
  }
}
