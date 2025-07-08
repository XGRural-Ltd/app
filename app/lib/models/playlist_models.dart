import 'package:flutter/foundation.dart';
import 'song_models.dart';

class Playlist {
  String id;
  String name;
  List<Song> songs;
  String? mood;
  String? danceable;
  int? adventurousness;

  Playlist({
    required this.id,
    required this.name,
    this.songs = const [],
    this.mood,
    this.danceable,
    this.adventurousness,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((song) => song.toMap()).toList(),
      'mood': mood,
      'danceable': danceable,
      'adventurousness': adventurousness,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      songs: (map['songs'] as List<dynamic>?)
              ?.map((songMap) => Song.fromMap(songMap))
              .toList() ??
          [],
    );
  }
}