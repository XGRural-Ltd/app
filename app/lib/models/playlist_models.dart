import 'package:cloud_firestore/cloud_firestore.dart';
import 'music_models.dart';

class Playlist {
  final String? id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final List<Music> musics;
  final GeoPoint? geolocation;

  Playlist({
    this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.musics,
    this.geolocation,
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
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'userId': userId,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'musics': musics.map((music) => music.toMap()).toList(),
      if (geolocation != null) 'geolocation': geolocation,
    };
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'userId': userId,
      'name': name,
      'musics': musics.map((music) => music.toMap()).toList(),
      if (geolocation != null) 'geolocation': geolocation,
    };
  }

}