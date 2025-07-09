import 'package:app/models/music_models.dart';
import 'package:app/models/playlist_models.dart';
import 'package:app/services/playlist_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'presentation/screens/create_playlist.dart';

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
        scaffoldBackgroundColor: Colors.white,
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
                  "https://storage.googleapis.com/tune-tap-app-images/tunetap_logo_transparent.png",
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
  bool _isLoading = true; // Novo estado de carregamento

  @override
  void initState() {
    super.initState();
    _initializeUserAndLoadPlaylists();
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

  Future<void> _addExamplePlaylist(String playlistName) async {
    if (_currentUserId == null) {
      print("Erro: Nenhum usuário logado para adicionar playlist.");
      return;
    }

    final newMusics = [
      Music(
        title: "Bohemian Rhapsody",
        artist: "Queen",
        albumImage: "https://placehold.co/64x64/7e57c2/white?text=S1",
        duration: "2:80",
      ),
      Music(
        title: "Stairway to Heaven",
        artist: "Led Zeppelin",
        albumImage: "https://placehold.co/64x64/7e57c2/white?text=S1",
        duration: "1:60",
      ),
    ];

    final newPlaylist = Playlist(
      userId: _currentUserId!, // Passa o ID do usuário logado
      name: playlistName,
      createdAt: DateTime.now(),
      musics: newMusics,
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
        builder:
            (context) => CreatePlaylistScreen(
              onCreate: (String playlistName) async {
                await _addExamplePlaylist(playlistName);
              },
            ),
      ),
    );
  }

  Future<void> _updateExamplePlaylist(Playlist playlistToUpdate) async {
    if (_currentUserId == null) {
      print("Erro: Nenhum usuário logado para atualizar playlist.");
      return;
    }

    // Exemplo: Adicionar uma nova música à playlist
    final updatedMusics = List<Music>.from(playlistToUpdate.musics)..add(
      Music(
        title: "Nova Faixa",
        artist: "Colaborador",
        albumImage: "https://placehold.co/64x64/7e57c2/white?text=S1",
        duration: "2:00",
      ),
    );

    final updatedPlaylist = Playlist(
      id: playlistToUpdate.id, // Manter o ID para atualização
      userId: playlistToUpdate.userId, // Manter o userId original
      name: "${playlistToUpdate.name} (Editada)",
      createdAt: playlistToUpdate.createdAt, // Manter o createdAt original
      musics: updatedMusics,
    );

    // Passa o ID do usuário logado para o método de atualização
    bool success = await _playlistManager.updatePlaylistForUser(
      updatedPlaylist,
      _currentUserId!,
    );
    if (success) {
      print("Playlist ${playlistToUpdate.name} atualizada.");
    } else {
      print("Falha ao atualizar playlist.");
    }
  }

  Future<void> _deleteExamplePlaylist(String playlistId) async {
    if (_currentUserId == null) {
      print("Erro: Nenhum usuário logado para deletar playlist.");
      return;
    }

    // Passa o ID do usuário logado para o método de exclusão
    bool success = await _playlistManager.deletePlaylistForUser(
      playlistId,
      _currentUserId!,
    );
    if (success) {
      print("Playlist $playlistId deletada.");
    } else {
      print("Falha ao deletar playlist.");
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas playlists'),
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          icon: const Icon(Icons.menu),
          tooltip: "Menu de navegação",
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: const Color.fromARGB(255, 204, 204, 204),
            height: 1.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.music_note, color: Colors.purple),
                      title: Text(
                        _playlists[index].name,
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Text(
                        'Músicas: ${_playlists[index].musics.length}',
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext bc) {
                            return Container(
                              height: MediaQuery.of(bc).size.height * 0.5,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(25.0),
                                  topRight: Radius.circular(25.0),
                                ),
                              ),
                              child: StatefulBuilder(
                                // Adiciona um StatefulBuilder aqui para gerenciar o estado local do modal
                                builder: (
                                  BuildContext context,
                                  StateSetter modalSetState,
                                ) {
                                  // Variável de estado local para o nome da playlist dentro deste modal.
                                  // Ela é inicializada com o nome atual da playlist que foi passada para o onTap do ListTile.
                                  String currentModalPlaylistName =
                                      _playlists[index].name;

                                  return Column(
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10.0,
                                        ),
                                        child: Container(
                                          height: 5.0,
                                          width: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(
                                              2.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const SizedBox(width: 15),
                                            Text(
                                              currentModalPlaylistName, // <-- Este Text agora usa a variável de estado local
                                              style: const TextStyle(
                                                fontSize: 26,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.purple,
                                              ),
                                              tooltip:
                                                  "Editar nome da playlist",
                                              onPressed: () async {
                                                String?
                                                novoNome = await showDialog<
                                                  String
                                                >(
                                                  context: context,
                                                  builder: (dialogContext) {
                                                    // O TextEditingController é inicializado com o nome atual do modal
                                                    final _editController =
                                                        TextEditingController(
                                                          text:
                                                              currentModalPlaylistName,
                                                        );
                                                    return AlertDialog(
                                                      title: const Text(
                                                        'Editar nome da playlist',
                                                      ),
                                                      content: TextField(
                                                        controller:
                                                            _editController,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText:
                                                                  'Novo nome',
                                                            ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    dialogContext,
                                                                  ).pop(),
                                                          child: const Text(
                                                            'Cancelar',
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                              dialogContext,
                                                            ).pop(
                                                              _editController
                                                                  .text
                                                                  .trim(),
                                                            );
                                                          },
                                                          child: const Text(
                                                            'Salvar',
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                                if (novoNome != null &&
                                                    novoNome.isNotEmpty &&
                                                    novoNome !=
                                                        currentModalPlaylistName) {
                                                  // Cria uma cópia da playlist com o novo nome
                                                  final updatedPlaylist = Playlist(
                                                    id: _playlists[index].id,
                                                    userId:
                                                        _playlists[index]
                                                            .userId,
                                                    name:
                                                        novoNome, // Usa o nome obtido do input do usuário
                                                    createdAt:
                                                        _playlists[index]
                                                            .createdAt,
                                                    musics:
                                                        _playlists[index]
                                                            .musics,
                                                  );

                                                  // Envia a atualização para o Firestore
                                                  await _playlistManager
                                                      .updatePlaylistForUser(
                                                        updatedPlaylist,
                                                        _currentUserId!,
                                                      );

                                                  // --- FUNÇÃO PARA ATUALIZAR O WIDGET TEXT DENTRO DESTE CONTAINER ---
                                                  // Chama o setState do StatefulBuilder (modalSetState)
                                                  // Isso reconstrói *apenas* o conteúdo do BottomSheet,
                                                  // atualizando o Text com o 'novoNome' imediatamente.
                                                  modalSetState(() {
                                                    currentModalPlaylistName =
                                                        novoNome;
                                                  });
                                                  // O StreamBuilder principal da HomePage ainda detectará a mudança no Firestore
                                                  // e reconstruirá a lista principal de playlists (ListTile.title), garantindo
                                                  // que a interface inteira esteja sincronizada após a operação no banco de dados.
                                                }
                                              },
                                            ),
                                            const Spacer(),
                                            const FaIcon(
                                              FontAwesomeIcons.spotify,
                                              color: Colors.green,
                                              size: 30,
                                            ),
                                            const SizedBox(width: 10),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 13),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              children: [
                                                ..._playlists[index].musics
                                                    .map<Widget>(
                                                      (song) => Container(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 3,
                                                            ),
                                                        alignment:
                                                            Alignment
                                                                .centerLeft,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            Text(
                                                              song.title,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              song.artist,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              height: 6,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 10.0,
                                        ),
                                        child: Align(
                                          alignment: Alignment.bottomRight,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: const Icon(Icons.delete),
                                            label: const Text(
                                              'Deletar Playlist',
                                            ),
                                            onPressed: () async {
                                              Navigator.of(
                                                bc,
                                              ).pop(); // Fecha o bottom sheet
                                              if (_currentUserId != null &&
                                                  _playlists[index].id !=
                                                      null) {
                                                await _playlistManager
                                                    .deletePlaylistForUser(
                                                      _playlists[index].id!,
                                                      _currentUserId!,
                                                    );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
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
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        backgroundColor: Colors.white,
        onPressed: () => _createNewPlaylist(context),
        tooltip: "Adicionar nova playlist.",
        child: const Icon(Icons.add, color: Colors.purple, size: 35),
      ),
    );
  }
}
