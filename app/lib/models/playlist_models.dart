import 'package:cloud_firestore/cloud_firestore.dart';
import 'music_models.dart';

class Playlist {
  final String? id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final List<Music> musics;
  final GeoPoint? geolocation;
  final bool? isFavorite ;
  final String? playlistImageUrl;

  Playlist({
    this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.musics,
    this.geolocation,
    this.isFavorite,
    this.playlistImageUrl,
  });

  factory Playlist.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Playlist(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unnamed Playlist',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      musics: (data['musics'] as List<dynamic>?)
              ?.map((musicMap) => Music.fromMap(musicMap as Map<String, dynamic>))
              .toList() ??
          [],
      geolocation: data['geolocation'] as GeoPoint?,
      isFavorite: data['isFavorite'],
      playlistImageUrl: data['playlistImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'userId': userId,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'musics': musics.map((music) => music.toMap()).toList(),
      if (geolocation != null) 'geolocation': geolocation,
      'isFavorite': isFavorite ?? false,
      if (playlistImageUrl != null) 'playlistImageUrl': playlistImageUrl,
    };
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'userId': userId,
      'name': name,
      'musics': musics.map((music) => music.toMap()).toList(),
      if (geolocation != null) 'geolocation': geolocation,
      'isFavorite': isFavorite,
      if (playlistImageUrl != null) 'playlistImageUrl': playlistImageUrl,
    };
  }

  Playlist copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
    List<Music>? musics,
    GeoPoint? geolocation,
    bool? isFavorite,
    String? playlistImageUrl,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      musics: musics ?? this.musics,
      geolocation: geolocation ?? this.geolocation,
      isFavorite: isFavorite ?? this.isFavorite,
      playlistImageUrl: playlistImageUrl ?? this.playlistImageUrl,
    );
  }

}