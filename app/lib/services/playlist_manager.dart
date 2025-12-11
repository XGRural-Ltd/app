import 'package:flutter/material.dart';
import '../models/playlist_models.dart';
import '../models/music_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Gerencia o estado e as operações das playlists.
/// Estende ChangeNotifier para notificar os ouvintes (Widgets) sobre mudanças.
class PlaylistManager extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _playlistsCollection => _firestore.collection('playlists');

  Future<String?> addPlaylist(Playlist playlist, {String? playlistId}) async {
    try {
      if (playlistId != null) {
        // Define um ID de documento específico
        await _playlistsCollection.doc(playlistId).set(playlist.toFirestoreCreate());
        return playlistId;
      } else {
        // O Firestore gera um ID de documento automático
        DocumentReference docRef = await _playlistsCollection.add(playlist.toFirestoreCreate());
        return docRef.id;
      }
    } catch (e) {
      print('Erro ao adicionar playlist: $e');
      return null;
    }
  }

  Future<Playlist?> getPlaylistForUser(String playlistId, String userId) async {
    try {
      DocumentSnapshot doc = await _playlistsCollection.doc(playlistId).get();
      if (doc.exists) {
        Playlist playlist = Playlist.fromFirestore(doc);
        if (playlist.userId == userId) {
          return playlist;
        } else {
          print('Acesso negado: Playlist $playlistId não pertence ao usuário $userId.');
          return null;
        }
      } else {
        print('Playlist com ID $playlistId não encontrada.');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar playlist: $e');
      return null;
    }
  }

  Future<bool> toggleFavoriteForUser(Playlist playlist, String userId) async {
    if (playlist.id == null) {
      print('Erro: O ID da playlist não pode ser nulo para favoritar.');
      return false;
    }
    try {
      final isFavorite = playlist.isFavorite ?? false;
      final updatedPlaylist = playlist.copyWith(isFavorite: !isFavorite);
      return await updatePlaylistForUser(updatedPlaylist, userId);
    } catch (e) {
      print('Erro ao alternar favorito: $e');
      return false;
    }
  }

  Future<List<Playlist>> getPlaylistsForUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _playlistsCollection
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs
          .map((doc) => Playlist.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erro ao buscar playlists para o usuário $userId: $e');
      return [];
    }
  }

  Stream<List<Playlist>> streamPlaylistsForUser(String userId) {
    return _playlistsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Playlist.fromFirestore(doc))
              .toList();
        });
  }

  Stream<List<Playlist>> streamPlaylistsForAnotherUser(String userId) {
    return _playlistsCollection
        .where('userId', isNotEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Playlist.fromFirestore(doc))
              .toList();
        });
  }

  Future<bool> updatePlaylistForUser(Playlist playlist, String userId) async {
    if (playlist.id == null) {
      print('Erro: O ID da playlist não pode ser nulo para atualização.');
      return false;
    }
    try {
      // Primeiro, verifica se a playlist pertence ao usuário
      DocumentSnapshot doc = await _playlistsCollection.doc(playlist.id).get();
      if (doc.exists) {
        Playlist existingPlaylist = Playlist.fromFirestore(doc);
        if (existingPlaylist.userId == userId) {
          await _playlistsCollection.doc(playlist.id).update(playlist.toFirestoreUpdate());
          print('Playlist com ID ${playlist.id} atualizada com sucesso para o usuário $userId.');
          return true;
        } else {
          print('Acesso negado: Tentativa de atualizar playlist que não pertence ao usuário $userId.');
          return false;
        }
      } else {
        print('Playlist com ID ${playlist.id} não encontrada para atualização.');
        return false;
      }
    } catch (e) {
      print('Erro ao atualizar playlist: $e');
      return false;
    }
  }

  Future<bool> deletePlaylistForUser(String playlistId, String userId) async {
    try {
      // Primeiro, verifica se a playlist pertence ao usuário
      DocumentSnapshot doc = await _playlistsCollection.doc(playlistId).get();
      if (doc.exists) {
        Playlist existingPlaylist = Playlist.fromFirestore(doc);
        if (existingPlaylist.userId == userId) {
          await _playlistsCollection.doc(playlistId).delete();
          print('Playlist com ID $playlistId deletada com sucesso para o usuário $userId.');
          return true;
        } else {
          print('Acesso negado: Tentativa de deletar playlist que não pertence ao usuário $userId.');
          return false;
        }
      } else {
        print('Playlist com ID $playlistId não encontrada para exclusão.');
        return false;
      }
    } catch (e) {
      print('Erro ao deletar playlist: $e');
      return false;
    }
  }

  Future<bool> updatePlaylistImageUrl(String playlistId, String userId, String newImageUrl) async {
    try {
      // Verifica se a playlist pertence ao usuário
      DocumentSnapshot doc = await _playlistsCollection.doc(playlistId).get();
      if (doc.exists) {
        Playlist existingPlaylist = Playlist.fromFirestore(doc);
        if (existingPlaylist.userId == userId) {
          await _playlistsCollection.doc(playlistId).update({
            'playlistImageUrl': newImageUrl,
          });
          print('Imagem da playlist com ID $playlistId atualizada com sucesso para o usuário $userId.');
          return true;
        } else {
          print('Acesso negado: Tentativa de atualizar imagem de playlist que não pertence ao usuário $userId.');
          return false;
        }
      } else {
        print('Playlist com ID $playlistId não encontrada para atualização de imagem.');
        return false;
      }
    } catch (e) {
      print('Erro ao atualizar imagem da playlist: $e');
      return false;
    }
  }
}