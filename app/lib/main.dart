import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package.cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:http/http.dart' as http; 
import 'dart:convert'; 


class SpotifyService { 
  final String _clientId = 'YOUR_SPOTIFY_CLIENT_ID'; 
  final String _clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET'; 
  String? _accessToken; 

  Future<void> _getAccessToken() async { 
    if (_accessToken != null) return; 

    var response = await http.post( 
      Uri.parse('https://accounts.spotify.com/api/token'), 
      headers: { 
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$_clientId:$_clientSecret')), 
        'Content-Type': 'application/x-www-form-urlencoded', 
      }, 
      body: 'grant_type=client_credentials', 
    ); 

    if (response.statusCode == 200) { 
      _accessToken = json.decode(response.body)['access_token']; 
    } else { 
      throw Exception('Failed to get Spotify access token'); 
    } 
  } 

  Future<Song> fetchTrackDetails(String trackName, String artistName) async { 
    await _getAccessToken(); 
  
    final searchUrl = Uri.parse('https://api.spotify.com/v1/search?q=track:${Uri.encodeComponent(trackName)}%20artist:${Uri.encodeComponent(artistName)}&type=track&limit=1'); 
    final searchResponse = await http.get(searchUrl, headers: {'Authorization': 'Bearer $_accessToken'}); 
  
    if (searchResponse.statusCode != 200) { 
      throw Exception('Failed to search for track'); 
    } 
  
    final searchResult = json.decode(searchResponse.body); 
    final tracks = searchResult['tracks']['items']; 
  
    if (tracks.isEmpty) { 
      return Song(name: trackName, artist: artistName, nationality: 'N/A', albumCoverUrl: 'https://placehold.co/64x64/purple/white?text=Error', location: LatLng(0,0)); 
    } 
  
    final trackData = tracks[0]; 
    final artistId = trackData['artists'][0]['id']; 
    final albumCoverUrl = trackData['album']['images'][0]['url'];
  
    final artistUrl = Uri.parse('https://api.spotify.com/v1/artists/$artistId'); 
    final artistResponse = await http.get(artistUrl, headers: {'Authorization': 'Bearer $_accessToken'}); 
  
    if (artistResponse.statusCode != 200) { 
      throw Exception('Failed to fetch artist details'); 
    } 
  
    final artistData = json.decode(artistResponse.body); 
    final markets = artistData['genres'] as List<dynamic>? ?? []; 
    final nationality = markets.isNotEmpty ? markets.first.toUpperCase() : 'N/A'; 
    
    Map<String, LatLng> countryCoordinates = { 
      "US": LatLng(38.9637, -95.7129), 
      "GB": LatLng(55.3781, -3.4360), 
      "BR": LatLng(-14.2350, -51.9253), 
      "JP": LatLng(36.2048, 138.2529), 
      "POP": LatLng(38.9637, -95.7129),
      "ROCK": LatLng(55.3781, -3.4360),
    }; 
    
    final location = countryCoordinates[nationality] ?? LatLng(0,0); 
  
    return Song( 
      name: trackName, 
      artist: artistName, 
      nationality: nationality, 
      albumCoverUrl: albumCoverUrl, 
      location: location, 
    ); 
  } 
} 

class Song { 
  final String name; 
  final String artist; 
  final String nationality;
  final String albumCoverUrl; 
  final LatLng location; 

  Song({ 
    required this.name, 
    required this.artist, 
    required this.nationality, 
    required this.albumCoverUrl, 
    required this.location, 
  }); 
} 

class Playlist { 
  String name; 
  List<Song> songs; 

  Playlist({required this.name, required this.songs}); 
} 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(TuneTapApp());
}

class TuneTapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TuneTap',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuário não encontrado no banco de dados.')),
          );
          await FirebaseAuth.instance.signOut();
        }
      } on FirebaseAuthException {
        // ...tratamento de erro...
      }
    }
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'TuneTap',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu e-mail';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return 'Por favor, insira um e-mail válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha';
                      } else if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Entrar',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Implementar a lógica de "Esqueceu a senha?"
              },
              child: Text(
                'Esqueceu a senha?',
                style: TextStyle(color: Colors.purple),
              ),
            ),
            TextButton(
              onPressed: _navigateToSignUp,
              child: Text(
                'Criar conta',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'password': _passwordController.text.trim(),
        });
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        String message = 'Erro ao criar conta';
        if (e.code == 'email-already-in-use') {
          message = 'E-mail já está em uso';
        } else if (e.code == 'weak-password') {
          message = 'Senha muito fraca';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Criar Conta', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu e-mail';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                      .hasMatch(value)) {
                    return 'Por favor, insira um e-mail válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha';
                  } else if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirme sua senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme sua senha';
                  } else if (value != _passwordController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Criar Conta',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Playlist> playlists = [ 
    Playlist( 
      name: 'Favoritos', 
      songs: [ 
        Song(name: 'Song 1', artist: 'Artist A', nationality: 'US', albumCoverUrl: 'https://placehold.co/64x64/7e57c2/white?text=S1', location: LatLng(34.0522, -118.2437)), 
        Song(name: 'Song 2', artist: 'Artist B', nationality: 'GB', albumCoverUrl: 'https://placehold.co/64x64/7e57c2/white?text=S2', location: LatLng(51.5074, -0.1278)), 
      ], 
    ), 
    Playlist( 
      name: 'Rock Clássico', 
      songs: [ 
        Song(name: 'Bohemian Rhapsody', artist: 'Queen', nationality: 'GB', albumCoverUrl: 'https://i.scdn.co/image/ab67616d0000b273e3344b360a45c3175c138a73', location: LatLng(51.5074, -0.1278)), 
        Song(name: 'Stairway to Heaven', artist: 'Led Zeppelin', nationality: 'GB', albumCoverUrl: 'https://i.scdn.co/image/ab67616d0000b2733d9c576547f3b85d34608c1f', location: LatLng(51.5074, -0.1278)), 
      ], 
    ), 
  ]; 

  void _createNewPlaylist(BuildContext context) { 
    Navigator.push( 
      context, 
      MaterialPageRoute( 
        builder: (context) => CreatePlaylistScreen( 
          onCreate: (String playlistName) async { 
            final spotifyService = SpotifyService(); 
            List<Song> generatedSongs = await Future.wait([ 
              spotifyService.fetchTrackDetails('Blinding Lights', 'The Weeknd'), 
              spotifyService.fetchTrackDetails('Watermelon Sugar', 'Harry Styles'), 
              spotifyService.fetchTrackDetails('good 4 u', 'Olivia Rodrigo'), 
            ]); 

            setState(() { 
              playlists.add( 
                  Playlist(name: playlistName, songs: generatedSongs)); 
            }); 
          }, 
        ), 
      ), 
    ); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TuneTap'),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bem-vindo ao TuneTap!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _createNewPlaylist(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                'Criar Nova Playlist',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Suas Playlists:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index]; 
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.music_note, color: Colors.purple),
                      title: Text(
                        playlist.name, 
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Text(
                        'Músicas: ${playlist.songs.length}', 
                      ),
                      trailing:
                          Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      onTap: () { 
                        Navigator.push( 
                          context, 
                          MaterialPageRoute( 
                            builder: (context) => PlaylistDetailScreen(playlist: playlist), 
                          ), 
                        ); 
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget { 
  final Playlist playlist; 

  const PlaylistDetailScreen({Key? key, required this.playlist}) : super(key: key); 

  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar( 
        title: Text(playlist.name, style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.purple, 
        actions: [ 
          IconButton( 
            icon: Icon(Icons.map, color: Colors.white), 
            onPressed: () { 
              Navigator.push( 
                context, 
                MaterialPageRoute( 
                  builder: (context) => PlaylistMapScreen(playlist: playlist), 
                ), 
              ); 
            }, 
          ), 
        ], 
      ), 
      body: ListView.builder( 
        itemCount: playlist.songs.length, 
        itemBuilder: (context, index) { 
          final song = playlist.songs[index]; 
          return ListTile( 
            leading: CircleAvatar( 
              backgroundImage: NetworkImage(song.albumCoverUrl), 
              radius: 30, 
              backgroundColor: Colors.purple.withOpacity(0.1), 
            ), 
            title: Text(song.name), 
            subtitle: Text(song.artist), 
            trailing: Text(song.nationality), 
          ); 
        }, 
      ), 
    ); 
  } 
} 

class PlaylistMapScreen extends StatefulWidget { 
  final Playlist playlist; 

  const PlaylistMapScreen({Key? key, required this.playlist}) : super(key: key); 

  @override 
  State<PlaylistMapScreen> createState() => _PlaylistMapScreenState(); 
} 

class _PlaylistMapScreenState extends State<PlaylistMapScreen> { 
  @override 
  Widget build(BuildContext context) { 
    List<Marker> markers = widget.playlist.songs.map((song) { 
      return Marker( 
        width: 80.0, 
        height: 80.0, 
        point: song.location, 
        child: Icon(Icons.music_note, color: Colors.red, size: 40.0), 
      ); 
    }).toList(); 

    return Scaffold( 
      appBar: AppBar( 
        title: Text('Mapa da Playlist: ${widget.playlist.name}', style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.purple, 
      ), 
      body: FlutterMap( 
        options: MapOptions( 
          initialCenter: widget.playlist.songs.isNotEmpty ? widget.playlist.songs.first.location : LatLng(0, 0), 
          initialZoom: 2.0, 
        ), 
        children: [ 
          TileLayer( 
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 
            userAgentPackageName: 'com.example.app', 
          ), 
          MarkerLayer(markers: markers), 
        ], 
      ), 
    ); 
  } 
} 

class CreatePlaylistScreen extends StatefulWidget {
  final Function(String) onCreate;

  CreatePlaylistScreen({required this.onCreate});

  @override
  _CreatePlaylistScreenState createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  String playlistName = '';
  String mood = '';
  String danceable = '';
  int adventurous = 5;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onCreate(playlistName);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Criar Nova Playlist', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nome da Playlist'),
                onChanged: (value) => playlistName = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um nome';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Agitado ou Calmo?'),
                items: [
                  DropdownMenuItem(value: 'Agitado', child: Text('Agitado')),
                  DropdownMenuItem(value: 'Calmo', child: Text('Calmo')),
                ],
                onChanged: (value) => mood = value!,
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Dançante ou Não?'),
                items: [
                  DropdownMenuItem(value: 'Dançante', child: Text('Dançante')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) => danceable = value!,
              ),
              SizedBox(height: 20),
              Text('Numa escala de 1 a 10, quão aventureiro você quer?'),
              Slider(
                value: adventurous.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: adventurous.toString(),
                onChanged: (value) =>
                    setState(() => adventurous = value.toInt()),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Criar Playlist',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
