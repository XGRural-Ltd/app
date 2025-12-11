import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:app/models/music_models.dart';
import 'package:app/models/playlist_models.dart';
import 'package:app/presentation/screens/playlist_map.dart';
import 'package:app/presentation/screens/playlist_info.dart';
import 'package:app/services/playlist_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'presentation/screens/create_playlist.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/services/spotify_manager.dart';
import 'presentation/screens/social_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TuneTapApp());
}

class TuneTapApp extends StatelessWidget {
  const TuneTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TuneTap',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      ),
      home: StreamBuilder<User?>(
        stream:
            FirebaseAuth.instance
                .authStateChanges(), // Escuta mudanças na autenticação
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return HomePage();
          } else {
            return LoginScreen();
          }
        },
      ),
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
        // Autentica o usuário
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        // Verifica se o usuário existe no Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();

        if (userDoc.exists) {
          // Usuário existe no Firestore, prossiga normalmente
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          // Usuário não existe no Firestore
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuário não encontrado no banco de dados.'),
            ),
          );
          // Opcional: deslogar o usuário
          await FirebaseAuth.instance.signOut();
        }
      } on FirebaseAuthException catch (e) {
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                height: 350,
                child: Image.network(
                  "https://storage.googleapis.com/tunetap_bucket/tunetap_logo_transparent.png",
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
                        } else if (!RegExp(
                          r'^[^@]+@[^@]+\.[^@]+',
                        ).hasMatch(value)) {
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
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        // Salva dados adicionais no Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
              'password':
                  _passwordController.text
                      .trim(), // Salvo em texto simples por enquanto
            });
        Navigator.pop(context);

        // Snackbar com mensagem de erro
      } on FirebaseAuthException catch (e) {
        String message = 'Erro ao criar conta';
        if (e.code == 'email-already-in-use') {
          message = 'E-mail já está em uso';
        } else if (e.code == 'weak-password') {
          message = 'Senha muito fraca';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
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
  final PlaylistManager _playlistManager = PlaylistManager();
  List<Playlist> _playlists = [];
  String? _currentUserId;
  bool _isLoading = true;
  final SpotifyManager _spotifyManager = SpotifyManager();
  String? _spotifyToken;
  String? _spotifyUserId;
  bool _showOnlyFavorites = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _initializeUserAndLoadPlaylists();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (_currentUserId != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
      setState(() {
        _userName = doc.data()?['name'] ?? '';
      });
    }
  }

  Future<void> _initializeUserAndLoadPlaylists() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _isLoading = false; // Usuário encontrado, carregamento concluído
      });
      print("Usuário logado: $_currentUserId");
      // Começa a escutar as playlists do usuário logado
      _playlistManager.streamPlaylistsForUser(_currentUserId!).listen((
        playlists,
      ) {
        setState(() {
          _playlists = playlists;
        });
        print("Playlists atualizadas: ${_playlists.length}");
      });
    } else {
      // Se não houver usuário, redirecione para o login
      print("Nenhum usuário logado. Redirecionando para LoginScreen.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Future<Map<String, dynamic>?> _getSpotifyTrackInfo(String query, String token) async {
    final url = Uri.https('api.spotify.com', '/v1/search', {
      'q': query,
      'type': 'track',
      'limit': '1',
    });

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final tracks = data['tracks']['items'] as List<dynamic>;
      if (tracks.isNotEmpty) {
        return tracks[0];
      }
    }
    return null;
  }

  Future<void> _addExamplePlaylist(String playlistName, String initialSong) async {
    if (_currentUserId == null) {
      print("Erro: Nenhum usuário logado para adicionar playlist.");
      return;
    } else { print('Logado com sucesso');}

    final token = await _spotifyManager.getSavedSpotifyToken();
    if (token == null) {
      print("Token do Spotify não encontrado.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Você precisa conectar ao Spotify!')),
      );
      return;
    } else {print('Token do Spotify obtido com sucesso');}

// Busca informações da música inicial
    List<Music> newMusics = [];
    
try {
  final uri = Uri.parse("http://35.238.38.246:5000/recommend");
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'track_1': initialSong}),
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);

    // Esperado:
    // {
    //   "recommended": [
    //     { "artists": "Artist X", "track_name": "Song X", "duration_ms": 185000 },
    //     ...
    //   ]
    // }
  
    final rec = body["recommended"];
    print("Recomendadas: $rec");
  
   

    // Adiciona 5 músicas aleatórias
    final usedTitles = <String>{};

    int added = 0;
    int queryIndex = 0;
    while (added < 5 ) {
      final randomInfo = await _getSpotifyTrackInfo(rec[queryIndex]["track_name"], token);
      queryIndex++;
      if (randomInfo != null && !usedTitles.contains(randomInfo['name'])) {
        newMusics.add(Music(
          title: randomInfo['name'],
          artist: (randomInfo['artists'] as List).isNotEmpty
              ? randomInfo['artists'][0]['name']
              : '',
          albumImage: (randomInfo['album']?['images'] as List).isNotEmpty
              ? randomInfo['album']['images'][0]['url']
              : "https://placehold.co/64x64/7e57c2/white?text=S1",
          duration: Duration(milliseconds: randomInfo['duration_ms'])
              .toString()
              .split('.')
              .first
              .substring(2, 7), // mm:ss
        ));
        usedTitles.add(randomInfo['name']);
        added++;
      }
    }
  }
} catch (e) {
 final musicInfo = await _getSpotifyTrackInfo(initialSong, token); 
 newMusics.add(Music(
          title: musicInfo?['name'],
          artist: (musicInfo?['artists'] as List).isNotEmpty
              ? musicInfo?['artists'][0]?['name']
              : '',
          albumImage: (musicInfo!['album']?['images'] as List).isNotEmpty
              ? musicInfo['album']['images'][0]['url']
              : "https://placehold.co/64x64/7e57c2/white?text=S1",
          duration: Duration(milliseconds: musicInfo['duration_ms'])
              .toString()
              .split('.')
              .first
              .substring(2, 7), // mm:ss
        ));
}

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    GeoPoint? geolocation;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      geolocation = GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      geolocation = null;
    }

    print("Geolocalização obtida: $geolocation");

    final newPlaylist = Playlist(
      userId: _currentUserId!, // Passa o ID do usuário logado
      name: playlistName,
      createdAt: DateTime.now(),
      musics: newMusics,
      geolocation: geolocation, // Adiciona o campo de geolocalização
    );

    String? docId = await _playlistManager.addPlaylist(newPlaylist);
    if (docId != null) {
      print("Playlist adicionada com sucesso! ID: $docId");
    } else {
      print("Falha ao adicionar playlist.");
    }
  }

  void _createNewPlaylist(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlaylistScreen(
          onCreate: (String playlistName, String initialSong) async {
            await _addExamplePlaylist(playlistName, initialSong);
          },
        ),
      ),
    );
  }

  // Função para realizar o logout
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      print("Usuário deslogado com sucesso!");
      // Redireciona para a tela de login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print("Erro ao deslogar: $e");
      // Opcional: exibir uma mensagem de erro para o usuário
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao deslogar: $e')));
    }
  }

  

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Mostra um indicador de carregamento enquanto o UID não está pronto
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUserId == null) {
      // Isso raramente aconteceria com o redirecionamento acima, mas é um fallback
      return const Scaffold(
        body: Center(child: Text('Erro: Usuário não autenticado.')),
      );
    }

    final displayedPlaylists = _showOnlyFavorites
        ? _playlists.where((p) => p.isFavorite == true).toList()
        : _playlists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas playlists'),
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(Icons.menu),
              tooltip: "Menu de navegação",
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: const Color.fromARGB(255, 204, 204, 204),
            height: 1.0,
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            // Cabeçalho do Drawer com nome do usuário
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.purple),
              accountName: Text(
                _userName ?? 'Carregando...',
                style: const TextStyle(fontSize: 22),
              ),
              accountEmail: null,
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.purple, size: 40),
              ),
            ),
            // Botão para configurações
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen(userId: _currentUserId!)),
                ).then((_) => _loadUserName()); // Atualiza nome ao voltar
              },
            ),
            // Botão para o mapa de playlists
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Mapa de Playlists'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapaPlaylistsPage(),
                  ),
                );
              },
            ),
            // Botão para integrar com o Spotify
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.spotify,
                color: Colors.green,
              ),
              title: const Text('Integrar com Spotify'),
              onTap: () async {
                _spotifyToken = await _spotifyManager.authenticateWithSpotify();
                _spotifyUserId = await _spotifyManager.getSpotifyUserId(
                  _spotifyToken!,
                );
                print('Token do Spotify: $_spotifyToken');
                print('User ID do Spotify: $_spotifyUserId');
                if (_spotifyToken != null && _spotifyUserId != null) {
                  Navigator.pop(context); // Fecha o Drawer

                  // Aguarda o Drawer fechar antes de mostrar o SnackBar
                  Future.delayed(Duration(milliseconds: 300), () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conectado ao Spotify com sucesso!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                      ),
                    );
                  });
                } else {
                  Navigator.pop(context);

                  Future.delayed(Duration(milliseconds: 300), () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Falha ao conectar ao Spotify.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Social'),
              onTap: () {
                Navigator.pop(context); // fecha drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SocialScreen()),
                );
              },
            ),
            const Spacer(), // Adiciona um espaço flexível para empurrar o botão de logout para o final
            // Botão para deslogar
            Align(
              alignment: Alignment.bottomCenter,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(color: Colors.red)),
                onTap: _logout, // Chama a função de logout
              ),
            ),
            const SizedBox(height: 16), // Espaço para o final do drawer
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Apenas favoritos',
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: _showOnlyFavorites,
                  activeColor: Colors.purple,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyFavorites = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                itemCount: displayedPlaylists.length,
                itemBuilder: (context, index) {
                  final playlist = displayedPlaylists[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Image.network(
                        (playlist.playlistImageUrl?.isNotEmpty ?? false)
                            ? playlist.playlistImageUrl!
                            : 'https://storage.googleapis.com/tunetap_bucket/tunetap_logo_transparent.png',
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          );
                        }, fit: BoxFit.cover,
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(fontSize: 18),
                      ),
                      subtitle: Text(
                        'Músicas: ${playlist.musics.length}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              playlist.isFavorite == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: playlist.isFavorite == true
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            tooltip: 'Favoritar',
                            onPressed: () => _playlistManager.toggleFavoriteForUser(playlist, _currentUserId!),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      onTap: () {
                        MaterialPageRoute route = MaterialPageRoute(
                          builder: (context) => PlaylistDetailsPage(
                            playlist: playlist,
                            currentUserId: _currentUserId,
                          ),
                        );
                        Navigator.push(context, route);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        backgroundColor: Colors.white,
        onPressed: () => _createNewPlaylist(context),
        tooltip: "Adicionar nova playlist.",
        child: const Icon(Icons.add, color: Color(0xFF9C27B0), size: 35),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final String userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  Future<void> _loadCurrentName() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    _nameController.text = doc.data()?['name'] ?? '';
  }

  Future<void> _saveName() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'name': _nameController.text.trim()});
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome atualizado com sucesso!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite seu nome' : null,
              ),
              const SizedBox(height: 30),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Salvar',
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
