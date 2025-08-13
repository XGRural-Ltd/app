import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app/models/music_models.dart';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyManager {
  String? _lastCodeVerifier; // Adicione esta variável de instância

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

  Future<String?> getSavedSpotifyToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('spotify_access_token');
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

  Future<String?> _createSpotifyPlaylist(Map<String, String> headers, String playlistName, String userId) async {
    // Criar playlist
    final createRes = await http.post(
      Uri.parse('https://api.spotify.com/v1/users/$userId/playlists'),
      headers: headers,
      body: jsonEncode({
        'name': playlistName,
        'public': false,
      }),
    );

    return jsonDecode(createRes.body)['id'];
  }

  Future<List<String>?> _getTrackUris(Map<String, String> headers, List<Music> musics, String token) async {

    final trackUris = <String>[];

    for (final music in musics) {
      final query = "artist:${music.artist} track:${music.title}";
      final encodedQuery = Uri.encodeComponent(query);
      final searchRes = await http.get(
        Uri.parse('https://api.spotify.com/v1/search?q=$encodedQuery&type=track&limit=10'),
        headers: headers,
      );

      if (searchRes.statusCode == 200) {
        final searchData = jsonDecode(searchRes.body);
        final tracks = searchData['tracks']['items'] as List<dynamic>;

        for (final track in tracks) {
          if (track['name'] == music.title && track['artists'][0]['name'] == music.artist) {
            final trackUri = track['uri'] as String;
            trackUris.add(trackUri);
            break;
          }
        }
      }
    }

    return trackUris.isNotEmpty ? trackUris : null;

  }

  Future<String?> _addMusicToSpotifyPlaylist(Map<String, String> headers, String playlistId, List<String> trackUris) async {
    final response = await http.post(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
      headers: headers,
      body: jsonEncode({
        'uris': trackUris,
      }),
    );

    if (response.statusCode == 201) {
      return 'Músicas adicionadas com sucesso!';
    } else {
      throw Exception('Erro ao adicionar músicas: ${response.body}');
    }
  }

  Future<void> createAndOpenSpotifyPlaylist(
    BuildContext context,
    String userId,
    List<Music> musics,
    String token,
    String playlistName,
  ) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    ValueNotifier<String> loadingMessage = ValueNotifier<String>('Criando playlist...');

    Future<void> showLoadingDialog() async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: loadingMessage,
                    builder: (context, value, _) => Text(value),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    try {
      await showLoadingDialog();

      loadingMessage.value = 'Criando playlist...';
      final playlistId = await _createSpotifyPlaylist(headers, playlistName, userId);
      await Future.delayed(const Duration(seconds: 2));

      loadingMessage.value = 'Buscando músicas...';
      final trackUris = await _getTrackUris(headers, musics, token);
      if (trackUris == null || trackUris.isEmpty) {
        throw Exception('Nenhuma música encontrada para adicionar à playlist.');
      } else {
        loadingMessage.value = '${trackUris.length} de ${musics.length} músicas encontradas.';
        await Future.delayed(const Duration(seconds: 2));
      }

      loadingMessage.value = 'Adicionando músicas...';
      await _addMusicToSpotifyPlaylist(headers, playlistId!, trackUris);
      await Future.delayed(const Duration(seconds: 2));

      loadingMessage.value = 'Playlist criada com sucesso!';
      await Future.delayed(const Duration(seconds: 2));

      loadingMessage.value = 'Abrindo Spotify...';
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pop();

      final playlistUrl = 'https://open.spotify.com/playlist/$playlistId';
      await launchUrl(
        Uri.parse(playlistUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    }
  }

  Future<String?> authenticateWithSpotify() async {
    final clientId = 'c02086dc4e6441ca93a58d2ad03fc62a';
    final redirectUri = 'tunetap://callback';
    final scopes =
        'playlist-modify-public playlist-modify-private user-read-private';

    // Gere e salve o code_verifier para este fluxo
    final codeVerifier = _generateCodeVerifier();
    _lastCodeVerifier = codeVerifier; // Salve aqui!
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

          // Use o code_verifier salvo!
          final tokenResponse = await http.post(
            Uri.parse('https://accounts.spotify.com/api/token'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'grant_type': 'authorization_code',
              'code': code!,
              'redirect_uri': redirectUri,
              'client_id': clientId,
              'code_verifier': _lastCodeVerifier!, // Use o salvo
            },
          );

          if (tokenResponse.statusCode == 200) {
            final json = jsonDecode(tokenResponse.body);
            final token = json['access_token'];
            print('Token de acesso obtido: $token');
            await saveSpotifyToken(token);
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

  Future<List<Map<String, dynamic>>> searchTracks(String query, String accessToken) async {
  final url = Uri.https('api.spotify.com', '/v1/search', {
    'q': query,
    'type': 'track',
    'limit': '10',
  });

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final tracks = data['tracks']['items'] as List<dynamic>;
    return tracks.map<Map<String, dynamic>>((track) {
      return {
        'name': track['name'],
        'artist': (track['artists'] as List).isNotEmpty
            ? track['artists'][0]['name']
            : '',
      };
    }).toList();
  } else {
    print('Erro ao buscar músicas no Spotify: ${response.body}');
    return [];
  }
}

}
