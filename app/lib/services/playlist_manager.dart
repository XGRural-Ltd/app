import 'package:flutter/material.dart';
import '../models/playlist_models.dart';
import '../models/song_models.dart';
import 'dart:math'; // Para gerar IDs aleatórios

/// Gerencia o estado e as operações das playlists.
/// Estende ChangeNotifier para notificar os ouvintes (Widgets) sobre mudanças.
class PlaylistManager extends ChangeNotifier {
  // Simula um banco de dados ou armazenamento local
  final List<Playlist> _playlists = [
    Playlist(
      id: 'p001',
      name: 'Favoritos',
      songs: [
        Song(name: 'Song 1', artist: 'Artist A', albumCoverUrl:'https://placehold.co/64x64/7e57c2/white?text=S1'),
        Song(name: 'Song 2', artist: 'Artist B', albumCoverUrl:'https://placehold.co/64x64/7e57c2/white?text=S1'),
        Song(name: 'Song 3', artist: 'Artist C', albumCoverUrl:'https://placehold.co/64x64/7e57c2/white?text=S1'),
      ],
    ),
    Playlist(
      id: 'p002',
      name: 'Rock Clássico',
      songs: [
        Song(name: 'Bohemian Rhapsody', artist: 'Queen', albumCoverUrl:'https://placehold.co/64x64/7e57c2/white?text=S1'),
        Song(name: 'Stairway to Heaven', artist: 'Led Zeppelin', albumCoverUrl:'https://placehold.co/64x64/7e57c2/white?text=S1'),
      ],
    ),
    Playlist(
      id: 'p003',
      name: 'Relaxamento',
      songs: [
        Song(name: 'Weightless', artist: 'Marconi Union', albumCoverUrl:'https://placehold.co/64x64/7e57c2/white?text=S1'),
        Song(name: 'Clair de Lune', artist: 'Debussy', albumCoverUrl:'https://placehold.co/64x64/7e57c2/white?text=S1'),
      ],
    ),
  ];

  // Retorna uma cópia imutável das playlists para evitar modificações externas diretas.
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  /// Adiciona uma nova playlist à lista.
  void addPlaylist(Playlist playlist) {
    // Gera um ID único se a playlist não tiver um
    playlist.id = playlist.id.isEmpty ? _generateUniqueId() : playlist.id;
    _playlists.add(playlist);
    notifyListeners(); // Notifica os Widgets que dependem deste manager
  }

  /// Remove uma playlist pelo seu ID.
  void removePlaylist(String playlistId) {
    _playlists.removeWhere((playlist) => playlist.id == playlistId);
    notifyListeners();
  }

  /// Adiciona uma música a uma playlist existente.
  void addSongToPlaylist(String playlistId, Song song) {
    try {
      final playlist =
          _playlists.firstWhere((p) => p.id == playlistId);
      playlist.songs.add(song);
      notifyListeners();
    } catch (e) {
      debugPrint('Playlist com ID $playlistId não encontrada: $e');
    }
  }

  /// Remove uma música de uma playlist existente.
  void removeSongFromPlaylist(String playlistId, Song song) {
    try {
      final playlist =
          _playlists.firstWhere((p) => p.id == playlistId);
      playlist.songs.removeWhere((s) => s.name == song.name && s.artist == song.artist);
      notifyListeners();
    } catch (e) {
      debugPrint('Playlist com ID $playlistId não encontrada: $e');
    }
  }

  /// Gera um ID único simples para as playlists (para demonstração).
  String _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }
}