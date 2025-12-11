import 'package:flutter/material.dart';
import 'package:app/models/playlist_models.dart';
import 'package:app/services/playlist_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app/services/uploader_manager.dart';

class PlaylistDetailsPage extends StatefulWidget {
  final Playlist playlist;
  final String? currentUserId;

  const PlaylistDetailsPage({
    super.key,
    required this.playlist,
    required this.currentUserId,
  });

  @override
  State<PlaylistDetailsPage> createState() => _PlaylistDetailsPageState();
}

class _PlaylistDetailsPageState extends State<PlaylistDetailsPage> {
  late String currentModalPlaylistName;
  final PlaylistManager _playlistManager = PlaylistManager();

  String? _currentImageUrl;

  // Dummy Spotify variables for demonstration; replace with your actual implementation
  String? _spotifyToken;
  String? _spotifyUserId;
  late dynamic _spotifyManager; // Replace with your actual SpotifyManager type

  @override
  void initState() {
    super.initState();
    currentModalPlaylistName = widget.playlist.name;
    _currentImageUrl = widget.playlist.playlistImageUrl;
    // Initialize your Spotify manager here if needed
    // _spotifyManager = SpotifyManager();
  }

  Future<void> _pickAndUploadImage() async {
    if (widget.currentUserId == null || widget.playlist.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário ou ID da playlist não disponível.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uploader = GCSUploader();

    // Mostrar dialog simples de progresso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uploadedUrl = await uploader.uploadImage();

      Navigator.of(context).pop(); // fecha o diálogo de progresso

      if (uploadedUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma imagem selecionada.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final success = await _playlistManager.updatePlaylistImageUrl(
        widget.playlist.id!,
        widget.currentUserId!,
        uploadedUrl,
      );

      if (success) {
        setState(() {
          _currentImageUrl = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagem da playlist atualizada com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao atualizar a imagem no servidor.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // fecha o diálogo se ocorreu erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
              Center(
              child: Stack(
                children: [
                Image.network(
                  _currentImageUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.blue),
                  tooltip: 'Alterar imagem',
                  onPressed: _pickAndUploadImage,
                  ),
                ),
                ],
              ),
              ),
            if (_currentImageUrl == null || _currentImageUrl!.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickAndUploadImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Adicionar imagem'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 35),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const SizedBox(width: 15),
                  Text(
                    currentModalPlaylistName,
                    style: const TextStyle(fontSize: 26),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.spotify,
                      color: Colors.green,
                      size: 30,
                    ),
                    onPressed: () async {
                      if (_spotifyToken == null || _spotifyUserId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Conecte-se ao Spotify antes de exportar a playlist.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        await _spotifyManager.createAndOpenSpotifyPlaylist(
                          context,
                          _spotifyUserId!,
                          widget.playlist.musics,
                          _spotifyToken!,
                          widget.playlist.name,
                        );
                      } catch (e, st) {
                        print(
                          'Erro ao exportar playlist para Spotify: $e\n$st',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao exportar para Spotify: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    widget.playlist.isFavorite == true ? Icons.favorite : Icons.favorite_border,
                    color: widget.playlist.isFavorite == true ? Colors.red : Colors.grey,
                  ),
                  tooltip: 'Favoritar',
                  onPressed: () => _playlistManager.toggleFavoriteForUser(
                    widget.playlist,
                    widget.currentUserId!,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.purple),
                  tooltip: "Editar nome da playlist",
                  onPressed: () async {
                    String? novoNome = await showDialog<String>(
                      context: context,
                      builder: (dialogContext) {
                        final _editController = TextEditingController(
                          text: currentModalPlaylistName,
                        );
                        return AlertDialog(
                          title: const Text('Editar nome da playlist'),
                          content: TextField(
                            controller: _editController,
                            decoration: const InputDecoration(
                              labelText: 'Novo nome',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(
                                  dialogContext,
                                ).pop(_editController.text.trim());
                              },
                              child: const Text('Salvar'),
                            ),
                          ],
                        );
                      },
                    );
                    if (novoNome != null && novoNome.isNotEmpty && novoNome != currentModalPlaylistName) {
                      final updatedPlaylist = Playlist(
                        id: widget.playlist.id,
                        userId: widget.playlist.userId,
                        name: novoNome,
                        createdAt: widget.playlist.createdAt,
                        musics: widget.playlist.musics,
                      );

                      await _playlistManager.updatePlaylistForUser(
                        updatedPlaylist,
                        widget.currentUserId!,
                      );
                      setState(() {
                        currentModalPlaylistName = novoNome;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 2),
                itemCount: widget.playlist.musics.length,
                itemBuilder: (context, index) {
                  final music = widget.playlist.musics[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(music.albumImage),
                    ),
                    title: Text(music.title),
                    subtitle: Text('${music.artist} - ${music.duration}'),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Deletar Playlist'),
                        content: const Text(
                          'Tem certeza que deseja deletar esta playlist?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Deletar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && widget.currentUserId != null && widget.playlist.id != null) {
                      Navigator.of(context).pop(); // Fecha o bottom sheet ou página
                      await _playlistManager.deletePlaylistForUser(
                        widget.playlist.id!,
                        widget.currentUserId!,
                      );
                    }
                  },
                  child: const Icon(Icons.delete), // Added required child
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
