import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app/services/spotify_manager.dart';

class CreatePlaylistScreen extends StatefulWidget {
  final void Function(String, String) onCreate; // nome, música inicial

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

  String? initialSong;

  final TextEditingController _initialSongController = TextEditingController();

  final SpotifyManager _spotifyManager = SpotifyManager();

  Future<void> _searchAndSelectSong(TextEditingController controller) async {
    String? selected = await showDialog<String>(
      context: context,
      builder: (context) {
        String query = '';
        List<Map<String, dynamic>> results = [];
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Buscar música no Spotify'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Nome da música'),
                    onChanged: (value) => query = value,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => isLoading = true);
                      final token = await _spotifyManager.getSavedSpotifyToken();
                      if (token == null) {
                        setState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Você precisa conectar ao Spotify!')),
                        );
                        return;
                      }
                      results = await _spotifyManager.searchTracks(query, token);
                      setState(() => isLoading = false);
                    },
                    child: Text('Buscar'),
                  ),
                  if (isLoading) CircularProgressIndicator(),
                  if (!isLoading && results.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final track = results[index];
                          return ListTile(
                            title: Text(track['name']),
                            subtitle: Text(track['artist']),
                            onTap: () {
                              Navigator.of(context).pop('${track['name']} - ${track['artist']}');
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected != null) {
      controller.text = selected;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onCreate(
        playlistName,
        _initialSongController.text,
      );
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _initialSongController,
                        decoration: InputDecoration(labelText: 'Música inicial'),
                        readOnly: true,
                        onTap: () => _searchAndSelectSong(_initialSongController),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecione a música inicial';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.purple),
                      onPressed: () => _searchAndSelectSong(_initialSongController),
                    ),
                  ],
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