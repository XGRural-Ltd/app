import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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