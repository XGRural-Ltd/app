import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      // Autentica o usuário
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Verifica se o usuário existe no Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
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
          SnackBar(content: Text('Usuário não encontrado no banco de dados.')),
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
           SizedBox(width: double.infinity,
           height: 350,
           child: Image.network(
            "https://storage.googleapis.com/tune-tap-app-images/tunetap_logo_transparent.png",
            )),
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
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Salva dados adicionais no Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'password': _passwordController.text.trim(), // Salvo em texto simples por enquanto
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
  List<Map<String, dynamic>> playlists = [
    {
      'name': 'Favoritos',
      'songs': [['Song 1', 'Artist A'], ['Song 2','Artist B'], ['Song 3','Artist C']]
    },
    {
      'name': 'Rock Clássico',
      'songs': [['Bohemian Rhapsody', 'Queen'], ['Stairway to Heaven','Led Zeppelin']]
    },
    {
      'name': 'Relaxamento',
      'songs': [['Weightless', 'Marconi Union'], ['Clair de Lune', 'Debussy']]
    },
  ];

  void _createNewPlaylist(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlaylistScreen(
          onCreate: (String playlistName) {
            setState(() {
              playlists.add({
                'name': playlistName,
                'songs': [
                  'Generated Song 1',
                  'Generated Song 2',
                  'Generated Song 3'
                ]
              });
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
        title: Text('Minhas playlists'),
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          onPressed: (){
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
          )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.music_note, color: Colors.purple),
                      title: Text(
                        playlists[index]['name'],
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Text(
                        'Músicas: ${playlists[index]['songs'].length}',
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext bc){
                            return Container(
                              height: MediaQuery.of(bc).size.height * 0.5,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(25.0),
                                  topRight: Radius.circular(25.0)
                                )
                              ),
                              child: Column(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: Container(
                                      height: 5.0,
                                      width: 40.0,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2.5)
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    child: SizedBox(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              const SizedBox(width: 15),
                                              Text(
                                                playlists[index]['name'],
                                                style: TextStyle(fontSize: 26),
                                                ),
                                              const Spacer(),
                                              FaIcon(
                                                FontAwesomeIcons.spotify,
                                                color: Colors.green,
                                                size: 30,
                                              ),
                                              const SizedBox(width: 10)
                                            ],
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: 13),
                                  Expanded(
                                    child: SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              children: [
                                              ...playlists[index]['songs']
                                              .map<Widget>((song) => Container(
                                                padding: EdgeInsets.only(bottom: 3),
                                                alignment: Alignment.centerLeft,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                    '${song[1]}',
                                                    style: const TextStyle(fontSize: 10),
                                                    ),
                                                    SizedBox(height: 2),
                                                    Text(
                                                      '${song[0]}',
                                                      style: const TextStyle(fontSize: 15)
                                                    ),
                                                    SizedBox(height: 6)
                                                  ]),
                                                )).toList()
                                              ],
                                            ),
                                          ),
                                        ),
                                  )
                                  /*Expanded(
                                    child: Column(
                                      children: <Widget>[
                                        SizedBox(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              const SizedBox(width: 15),
                                              Text(
                                                playlists[index]['name'],
                                                style: TextStyle(fontSize: 26),
                                                ),
                                              const Spacer(),
                                              FaIcon(
                                                FontAwesomeIcons.spotify,
                                                color: Colors.green,
                                                size: 30,
                                              ),
                                              const SizedBox(width: 10)
                                              //IconButton(onPressed: () {}, icon: Icon(Icons.music_note)),
                                              //IconButton(onPressed: () {}, icon: Icon(Icons.music_note)),
                                            ],
                                          ),
                                        ),
                                        SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              children: [
                                              ...playlists[index]['songs']
                                              .map<Widget>((song) => Container(
                                                padding: EdgeInsets.only(bottom: 15),
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  '$song',
                                                  style: const TextStyle(fontSize: 16)
                                                  ),
                                                )).toList()
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),*/
                                ],
                              ),
                            );
                          });
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        backgroundColor: Colors.white,
        onPressed: () => _createNewPlaylist(context),
        tooltip: "Adicionar nova playlist.",
        child: const Icon(Icons.add, color: Colors.purple,size: 35,),
        )
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
        title: Text('Adicionar playlist'),
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          onPressed: (){
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
          tooltip: "Back",
          ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: const Color.fromARGB(255, 204, 204, 204),
            height: 1.0,
          )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                TextFormField(
                  decoration: InputDecoration(labelText: 'Música inicial'),
                  ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Música final'),
                  ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Heterogeneidade'),
                  items: [
                    DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                    DropdownMenuItem(value: 'Não', child: Text('Não')),
                  ],
                  onChanged: (value) => danceable = value!,
                ),
                SizedBox(height: 20),
                Text('Duração estimada (min)'),
                Slider(
                  value: adventurous.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: adventurous.toString(),
                  onChanged: (value) => setState(() => adventurous = value.toInt()),
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
        )
        ),
      ),
    );
  }
}